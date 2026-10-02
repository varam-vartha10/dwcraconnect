const User = require("../models/User");
const Loan = require("../models/Loan");
const Emi = require("../models/Emi");
const Transaction = require("../models/Transaction");
const Subsidy = require("../models/Subsidy");
const Notification = require("../models/Notification");
const { getMyLoanSummary, getMyEmiSummary } = require("./accountSummaryService");

/**
 * Group Summary Service
 * Central source of truth for Group Leader (President / Secretary) Dashboard & Chatbot.
 */

const getGroupSummary = async (groupId) => {
  if (!groupId) {
    throw new Error("groupId is required for group summary");
  }

  // 1. Fetch group members
  const members = await User.find({ groupId, isActive: true }).select("-password").lean();
  const president = members.find(m => m.position === "president") || null;
  const secretary = members.find(m => m.position === "secretary") || null;

  // 2. Fetch group-level financial records
  const groupLoans = await Loan.find({ groupId, status: { $ne: "cancelled" } }).lean();
  const groupEmis = await Emi.find({ groupId }).sort({ dueDate: 1 }).lean();
  const groupTxs = await Transaction.find({ groupId }).sort({ paymentDate: -1 }).lean();
  const groupSubsidies = await Subsidy.find({ groupId }).sort({ createdAt: -1 }).lean();

  const now = new Date();

  // 3. Group Loan Metrics
  const activeLoans = groupLoans.filter(l => ["active", "pending", "overdue"].includes(l.status));
  const totalGroupPrincipal = groupLoans.reduce((sum, l) => sum + (l.principalAmount || 0), 0);
  const activeGroupPrincipal = activeLoans.reduce((sum, l) => sum + (l.principalAmount || 0), 0);

  const completedTxs = groupTxs.filter(t => t.type === "loan_payment" && t.status === "completed");
  const totalTxPaid = completedTxs.reduce((sum, t) => sum + (t.amount || 0), 0);
  const paidEmis = groupEmis.filter(e => e.status === "paid");
  const totalEmiPaid = paidEmis.reduce((sum, e) => sum + (e.amount || 0), 0);
  const totalGroupPaid = Math.max(totalTxPaid, totalEmiPaid);
  const totalGroupRemaining = Math.max(0, activeGroupPrincipal - totalGroupPaid);

  // 4. Group EMI Metrics
  const unpaidEmis = groupEmis.filter(e => e.status !== "paid");
  const overdueEmis = unpaidEmis.filter(e => new Date(e.dueDate) < now);
  const upcomingEmis = unpaidEmis.filter(e => new Date(e.dueDate) >= now);

  const totalGroupSubsidies = groupSubsidies.reduce((sum, s) => sum + (s.amount || 0), 0);

  // 5. Member-wise breakdown
  const memberSummaries = await Promise.all(
    members.map(async (m) => {
      const loanSummary = await getMyLoanSummary(m.userId, groupId, "member");
      const emiSummary = await getMyEmiSummary(m.userId, groupId, "member");

      const primaryEmi = emiSummary.nextUpcomingEmi || emiSummary.primaryOverdueEmi;

      return {
        userId: m.userId,
        name: m.name,
        role: m.role,
        position: m.position,
        phoneNumber: m.phoneNumber,
        village: m.village,
        totalPrincipal: loanSummary.totalPrincipal,
        totalPaid: loanSummary.totalPaid,
        remainingBalance: loanSummary.remainingBalance,
        activeLoanCount: loanSummary.activeLoanCount,
        hasOverdueEmi: emiSummary.overdueEmisCount > 0,
        nextEmiAmount: primaryEmi ? primaryEmi.amount : 0,
        nextEmiDueDate: primaryEmi ? primaryEmi.dueDate : null,
        nextEmiStatus: primaryEmi ? (new Date(primaryEmi.dueDate) < now ? "overdue" : primaryEmi.status) : "none",
      };
    })
  );

  return {
    groupId,
    totalMembers: members.length,
    activeMembersCount: members.length,
    president: president ? { userId: president.userId, name: president.name } : null,
    secretary: secretary ? { userId: secretary.userId, name: secretary.name } : null,
    totalGroupPrincipal,
    activeGroupPrincipal,
    totalGroupPaid,
    totalGroupRemaining,
    totalGroupEmis: groupEmis.length,
    paidGroupEmisCount: paidEmis.length,
    pendingGroupEmisCount: upcomingEmis.length,
    overdueGroupEmisCount: overdueEmis.length,
    totalGroupSubsidiesCount: groupSubsidies.length,
    totalGroupSubsidyAmount: totalGroupSubsidies,
    totalGroupTransactionsCount: groupTxs.length,
    memberSummaries,
  };
};

module.exports = {
  getGroupSummary,
};
