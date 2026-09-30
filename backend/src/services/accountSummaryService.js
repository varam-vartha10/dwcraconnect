const User = require("../models/User");
const Loan = require("../models/Loan");
const Emi = require("../models/Emi");
const Transaction = require("../models/Transaction");
const Subsidy = require("../models/Subsidy");
const Notification = require("../models/Notification");

/**
 * Account Summary Service
 * Central source of truth for both Dashboard APIs and Chatbot API.
 * Supports Member personal view & Leader group view fallback.
 */

// 1. Loan Summary
const getMyLoanSummary = async (userId, groupId, role = "member") => {
  let filter = { memberId: userId, status: { $ne: "cancelled" } };
  let isGroupSummary = false;

  let loans = await Loan.find(filter).sort({ createdAt: -1 }).lean();

  // If leader has no personal loan, fetch group loans
  if (loans.length === 0 && (role === "leader" || role === "president" || role === "secretary") && groupId) {
    filter = { groupId: groupId, status: { $ne: "cancelled" } };
    loans = await Loan.find(filter).sort({ createdAt: -1 }).lean();
    isGroupSummary = true;
  }

  const txFilter = isGroupSummary ? { groupId: groupId, type: "loan_payment", status: "completed" } : { memberId: userId, type: "loan_payment", status: "completed" };
  const emiFilter = isGroupSummary ? { groupId: groupId, status: "paid" } : { memberId: userId, status: "paid" };

  const txs = await Transaction.find(txFilter).lean();
  const paidEmis = await Emi.find(emiFilter).lean();

  const totalTxPaid = txs.reduce((sum, t) => sum + (t.amount || 0), 0);
  const totalEmiPaid = paidEmis.reduce((sum, e) => sum + (e.amount || 0), 0);
  const totalPaid = Math.max(totalTxPaid, totalEmiPaid);

  const totalPrincipal = loans.reduce((sum, l) => sum + (l.principalAmount || 0), 0);
  const activeLoans = loans.filter(l => ["active", "pending", "overdue"].includes(l.status));
  const activePrincipal = activeLoans.reduce((sum, l) => sum + (l.principalAmount || 0), 0);
  const remainingBalance = Math.max(0, activePrincipal - totalPaid);

  return {
    hasLoans: loans.length > 0,
    isGroupSummary,
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
const getMyEmiSummary = async (userId, groupId, role = "member") => {
  let filter = { memberId: userId };
  let isGroupSummary = false;

  let emis = await Emi.find(filter).sort({ dueDate: 1 }).lean();

  if (emis.length === 0 && (role === "leader" || role === "president" || role === "secretary") && groupId) {
    filter = { groupId: groupId };
    emis = await Emi.find(filter).sort({ dueDate: 1 }).lean();
    isGroupSummary = true;
  }

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
    isGroupSummary,
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
const getMySubsidySummary = async (userId, groupId, role = "member") => {
  let filter = { memberId: userId };
  let isGroupSummary = false;

  let subsidies = await Subsidy.find(filter).sort({ createdAt: -1 }).lean();

  if (subsidies.length === 0 && (role === "leader" || role === "president" || role === "secretary") && groupId) {
    filter = { groupId: groupId };
    subsidies = await Subsidy.find(filter).sort({ createdAt: -1 }).lean();
    isGroupSummary = true;
  }

  const totalAmount = subsidies.reduce((sum, s) => sum + (s.amount || 0), 0);

  return {
    hasSubsidies: subsidies.length > 0,
    isGroupSummary,
    count: subsidies.length,
    totalAmount,
    subsidies,
  };
};

// 4. Transaction Summary
const getMyTransactionSummary = async (userId, groupId, role = "member", limit = 10) => {
  let filter = { memberId: userId };
  let isGroupSummary = false;

  let transactions = await Transaction.find(filter).sort({ paymentDate: -1 }).limit(limit).lean();

  if (transactions.length === 0 && (role === "leader" || role === "president" || role === "secretary") && groupId) {
    filter = { groupId: groupId };
    transactions = await Transaction.find(filter).sort({ paymentDate: -1 }).limit(limit).lean();
    isGroupSummary = true;
  }

  const totalPaid = transactions
    .filter(t => t.type === "loan_payment" && t.status === "completed")
    .reduce((sum, t) => sum + (t.amount || 0), 0);

  return {
    hasTransactions: transactions.length > 0,
    isGroupSummary,
    count: transactions.length,
    totalPaid,
    transactions,
  };
};

// 5. Notification Summary
const getMyNotificationSummary = async (userId, groupId, role = "member", limit = 10) => {
  let filter = { memberId: userId };
  let isGroupSummary = false;

  let notifications = await Notification.find(filter).sort({ createdAt: -1 }).limit(limit).lean();

  if (notifications.length === 0 && (role === "leader" || role === "president" || role === "secretary") && groupId) {
    filter = { groupId: groupId };
    notifications = await Notification.find(filter).sort({ createdAt: -1 }).limit(limit).lean();
    isGroupSummary = true;
  }

  const unreadCount = notifications.filter(n => !n.isRead).length;

  return {
    hasNotifications: notifications.length > 0,
    isGroupSummary,
    count: notifications.length,
    unreadCount,
    notifications,
  };
};

// 6. Complete Master Account Summary
const getMyAccountSummary = async (userId, groupId, role = "member") => {
  const user = await User.findOne({ userId }).select("-password").lean();
  const [loanSummary, emiSummary, subsidySummary, txSummary, notifSummary] = await Promise.all([
    getMyLoanSummary(userId, groupId, role),
    getMyEmiSummary(userId, groupId, role),
    getMySubsidySummary(userId, groupId, role),
    getMyTransactionSummary(userId, groupId, role),
    getMyNotificationSummary(userId, groupId, role),
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
