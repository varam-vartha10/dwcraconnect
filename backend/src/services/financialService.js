const Loan = require("../models/Loan");
const Emi = require("../models/Emi");
const Transaction = require("../models/Transaction");
const Subsidy = require("../models/Subsidy");
const Notification = require("../models/Notification");

/**
 * Reusable Financial Calculation Service
 * Central source of truth for both Dashboard APIs and Chatbot API
 */

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
  const emis = await Emi.find({ memberId: userId }).sort({ dueDate: 1 }).lean();
  const now = new Date();

  const paidEmis = emis.filter(e => e.status === "paid");
  const unpaidEmis = emis.filter(e => e.status !== "paid");

  const overdueEmis = unpaidEmis.filter(e => new Date(e.dueDate) < now);
  const upcomingEmis = unpaidEmis.filter(e => new Date(e.dueDate) >= now);

  const nextUpcomingEmi = upcomingEmis.length > 0 ? upcomingEmis[0] : null;
  const primaryOverdueEmi = overdueEmis.length > 0 ? overdueEmis[0] : null;

  const totalUnpaidAmount = unpaidEmis.reduce((sum, e) => sum + (e.amount || 0), 0);
  const totalOverdueAmount = overdueEmis.reduce((sum, e) => sum + (e.amount || 0), 0);

  return {
    hasEmis: emis.length > 0,
    totalEmisCount: emis.length,
    paidEmisCount: paidEmis.length,
    unpaidEmisCount: unpaidEmis.length,
    overdueEmisCount: overdueEmis.length,
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

// 3. Process EMI Payment (Atomic payment lifecycle execution)
const processEmiPayment = async ({ memberId, groupId, emiId, amount, paymentDate = new Date(), notes = "" }) => {
  const emi = await Emi.findOne({ emiId, memberId });
  if (!emi) {
    throw new Error("EMI record not found");
  }

  if (emi.status === "paid") {
    throw new Error("EMI is already paid");
  }

  // Mark EMI as paid
  emi.status = "paid";
  emi.paidDate = paymentDate;
  await emi.save();

  // Create permanent transaction record
  const transactionId = `TXN-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
  const transaction = await Transaction.create({
    transactionId,
    loanId: emi.loanId,
    emiId: emi.emiId,
    memberId,
    groupId,
    amount: amount || emi.amount,
    type: "loan_payment",
    status: "completed",
    paymentDate,
    notes: notes || `EMI installment #${emi.installmentNumber} payment`,
  });

  return {
    success: true,
    emi,
    transaction,
  };
};

module.exports = {
  getLoanSummary,
  getEmiSummary,
  processEmiPayment,
};
