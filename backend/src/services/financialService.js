const mongoose = require("mongoose");
const Loan = require("../models/Loan");
const Emi = require("../models/Emi");
const Transaction = require("../models/Transaction");
const Subsidy = require("../models/Subsidy");
const Notification = require("../models/Notification");
const { createPaymentSuccessNotification } = require("./notificationService");

/**
 * Reusable Financial Calculation Service
 * Central source of truth for both Dashboard APIs and Chatbot API
 */

// Helper to compute date-based EMI status
const computeEmiStatus = (emi, now = new Date()) => {
  if (emi.status === "paid" || emi.status === "waived") {
    return emi.status;
  }
  const dueDate = new Date(emi.dueDate);
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());

  if (dueDate < startOfToday) {
    return "overdue";
  } else if (
    dueDate.getFullYear() === now.getFullYear() &&
    dueDate.getMonth() === now.getMonth() &&
    dueDate.getDate() === now.getDate()
  ) {
    return "due";
  }
  return "pending";
};

// 1. Get Loan Summary
const getLoanSummary = async (userId) => {
  const loans = await Loan.find({ memberId: userId, status: { $ne: "cancelled" } }).lean();
  const txs = await Transaction.find({ memberId: userId, type: "loan_payment", status: "completed" }).lean();
  const paidEmis = await Emi.find({ memberId: userId, status: "paid" }).lean();

  const totalTxPaid = txs.reduce((sum, t) => sum + (t.amount || 0), 0);
  const totalEmiPaid = paidEmis.reduce((sum, e) => sum + (e.amount || 0), 0);
  const totalPaid = Math.max(totalTxPaid, totalEmiPaid);

  const totalPrincipal = loans.reduce((sum, l) => sum + (l.principalAmount || 0), 0);
  const activeLoans = loans.filter(l => ["active", "pending", "overdue"].includes(l.status));
  const activePrincipal = activeLoans.reduce((sum, l) => sum + (l.principalAmount || 0), 0);
  const remainingBalance = Math.max(0, activePrincipal - totalPaid);

  return {
    hasLoans: loans.length > 0,
    loanCount: loans.length,
    activeLoanCount: activeLoans.length,
    loans,
    activeLoans,
    totalPrincipal,
    activePrincipal,
    totalPaid,
    remainingBalance,
  };
};

// 2. Get EMI Summary
const getEmiSummary = async (userId) => {
  const rawEmis = await Emi.find({ memberId: userId }).sort({ dueDate: 1 }).lean();
  const now = new Date();

  // Attach computed date-based status
  const emis = rawEmis.map(e => ({
    ...e,
    computedStatus: computeEmiStatus(e, now),
  }));

  const paidEmis = emis.filter(e => e.status === "paid");
  const unpaidEmis = emis.filter(e => e.status !== "paid");

  const overdueEmis = unpaidEmis.filter(e => e.computedStatus === "overdue");
  const dueTodayEmis = unpaidEmis.filter(e => e.computedStatus === "due");
  const upcomingEmis = unpaidEmis.filter(e => e.computedStatus === "pending" || e.computedStatus === "due");

  const nextUpcomingEmi = upcomingEmis.length > 0 ? upcomingEmis[0] : (unpaidEmis.length > 0 ? unpaidEmis[0] : null);
  const primaryOverdueEmi = overdueEmis.length > 0 ? overdueEmis[0] : null;

  const totalUnpaidAmount = unpaidEmis.reduce((sum, e) => sum + (e.amount || 0), 0);
  const totalOverdueAmount = overdueEmis.reduce((sum, e) => sum + (e.amount || 0), 0);

  return {
    hasEmis: emis.length > 0,
    totalEmisCount: emis.length,
    paidEmisCount: paidEmis.length,
    unpaidEmisCount: unpaidEmis.length,
    overdueEmisCount: overdueEmis.length,
    dueTodayEmisCount: dueTodayEmis.length,
    upcomingEmisCount: upcomingEmis.length,
    nextUpcomingEmi,
    primaryOverdueEmi,
    totalUnpaidAmount,
    totalOverdueAmount,
    emis,
    paidEmis,
    unpaidEmis,
    overdueEmis,
    upcomingEmis,
  };
};

// 3. Process EMI Payment (Atomic, Transaction-Safe Payment Lifecycle Execution)
const processEmiPayment = async ({
  memberId,
  groupId,
  emiId,
  amount,
  paymentDate = new Date(),
  notes = "",
  userRole = "member",
}) => {
  if (!emiId) {
    throw new Error("emiId is required");
  }

  // 1. Find EMI
  const emi = await Emi.findOne({ emiId });
  if (!emi) {
    throw new Error("EMI record not found");
  }

  // 2. Ownership & Authorization Check
  if (userRole === "member" && emi.memberId !== memberId) {
    throw new Error("Unauthorized: You can only pay EMIs for your own account.");
  }

  if (userRole === "leader" && groupId && emi.groupId !== groupId) {
    throw new Error("Unauthorized: Cannot process payment for another group.");
  }

  // 3. Double Payment Protection
  if (emi.status === "paid") {
    throw new Error("This EMI has already been paid.");
  }

  // 4. Payment Amount Validation
  const payableAmount = emi.amount;
  const submittedAmount = Number(amount);

  if (isNaN(submittedAmount) || submittedAmount <= 0) {
    throw new Error("Invalid payment amount. Amount must be greater than zero.");
  }

  if (Math.abs(submittedAmount - payableAmount) > 0.01) {
    throw new Error(`Invalid payment amount. Submitted ₹${submittedAmount}, but required EMI amount is ₹${payableAmount}.`);
  }

  // 5. Transaction-Safe Database Execution using Session
  const session = await mongoose.startSession();
  try {
    session.startTransaction();

    // Mark EMI as paid
    emi.status = "paid";
    emi.paidDate = paymentDate;
    await emi.save({ session });

    // Create permanent transaction record
    const transactionId = `TXN-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
    const [transaction] = await Transaction.create(
      [
        {
          transactionId,
          loanId: emi.loanId,
          emiId: emi.emiId,
          memberId: emi.memberId,
          groupId: emi.groupId || groupId,
          amount: payableAmount,
          type: "loan_payment",
          status: "completed",
          paymentDate,
          notes: notes || `EMI installment #${emi.installmentNumber} payment`,
        },
      ],
      { session }
    );

    // Create payment success notification
    await createPaymentSuccessNotification({
      memberId: emi.memberId,
      groupId: emi.groupId || groupId,
      emi,
      transactionId,
      amount: payableAmount,
      session,
    });

    await session.commitTransaction();
    session.endSession();

    // Fetch updated post-payment account summaries
    const updatedLoanSummary = await getLoanSummary(emi.memberId);
    const updatedEmiSummary = await getEmiSummary(emi.memberId);

    return {
      success: true,
      message: "EMI payment successfully confirmed.",
      emi: emi.toObject ? emi.toObject() : emi,
      transaction: transaction.toObject ? transaction.toObject() : transaction,
      remainingBalance: updatedLoanSummary.remainingBalance,
      totalPaid: updatedLoanSummary.totalPaid,
      nextEmi: updatedEmiSummary.nextUpcomingEmi,
      unpaidEmisCount: updatedEmiSummary.unpaidEmisCount,
    };
  } catch (error) {
    await session.abortTransaction();
    session.endSession();
    throw error;
  }
};

module.exports = {
  computeEmiStatus,
  getLoanSummary,
  getEmiSummary,
  processEmiPayment,
};
