const User = require("../models/User");
const Loan = require("../models/Loan");
const Emi = require("../models/Emi");
const Transaction = require("../models/Transaction");
const Subsidy = require("../models/Subsidy");
const Notification = require("../models/Notification");

/**
 * Account Summary Service
 * Central source of truth for both Dashboard APIs and Chatbot API.
 */

// 1. Loan Summary
const getMyLoanSummary = async (userId, groupId) => {
  const filter = { memberId: userId };
  if (groupId) filter.groupId = groupId;

  const loans = await Loan.find(filter).sort({ createdAt: -1 }).lean();
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

// 2. EMI Summary
const getMyEmiSummary = async (userId, groupId) => {
  const filter = { memberId: userId };
  if (groupId) filter.groupId = groupId;

  const emis = await Emi.find(filter).sort({ dueDate: 1 }).lean();
  const now = new Date();

  const paidEmis = emis.filter(e => e.status === "paid");
  const unpaidEmis = emis.filter(e => e.status !== "paid");

  // Dynamically evaluate overdue vs upcoming for unpaid EMIs
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

// 3. Subsidy Summary
const getMySubsidySummary = async (userId, groupId) => {
  const filter = { memberId: userId };
  if (groupId) filter.groupId = groupId;

  const subsidies = await Subsidy.find(filter).sort({ createdAt: -1 }).lean();
  const totalAmount = subsidies.reduce((sum, s) => sum + (s.amount || 0), 0);

  return {
    hasSubsidies: subsidies.length > 0,
    count: subsidies.length,
    totalAmount,
    subsidies,
  };
};

// 4. Transaction Summary
const getMyTransactionSummary = async (userId, groupId, limit = 10) => {
  const filter = { memberId: userId };
  if (groupId) filter.groupId = groupId;

  const transactions = await Transaction.find(filter).sort({ paymentDate: -1 }).limit(limit).lean();
  const totalPaid = transactions
    .filter(t => t.type === "loan_payment" && t.status === "completed")
    .reduce((sum, t) => sum + (t.amount || 0), 0);

  return {
    hasTransactions: transactions.length > 0,
    count: transactions.length,
    totalPaid,
    transactions,
  };
};

// 5. Notification Summary
const getMyNotificationSummary = async (userId, groupId, limit = 10) => {
  const filter = { memberId: userId };
  if (groupId) filter.groupId = groupId;

  const notifications = await Notification.find(filter).sort({ createdAt: -1 }).limit(limit).lean();
  const unreadCount = notifications.filter(n => !n.isRead).length;

  return {
    hasNotifications: notifications.length > 0,
    count: notifications.length,
    unreadCount,
    notifications,
  };
};

// 6. Complete Master Account Summary
const getMyAccountSummary = async (userId, groupId) => {
  const user = await User.findOne({ userId }).select("-password").lean();
  const [loanSummary, emiSummary, subsidySummary, txSummary, notifSummary] = await Promise.all([
    getMyLoanSummary(userId, groupId),
    getMyEmiSummary(userId, groupId),
    getMySubsidySummary(userId, groupId),
    getMyTransactionSummary(userId, groupId),
    getMyNotificationSummary(userId, groupId),
  ]);

  return {
    user,
    loanSummary,
    emiSummary,
    subsidySummary,
    txSummary,
    notifSummary,
  };
};

module.exports = {
  getMyAccountSummary,
  getMyLoanSummary,
  getMyEmiSummary,
  getMySubsidySummary,
  getMyTransactionSummary,
  getMyNotificationSummary,
};
