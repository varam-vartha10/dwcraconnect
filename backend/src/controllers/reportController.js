const User = require("../models/User");
const Loan = require("../models/Loan");
const Emi = require("../models/Emi");
const Transaction = require("../models/Transaction");
const Subsidy = require("../models/Subsidy");

/**
 * GET /api/reports/:reportType
 * RBAC: Only Group Leaders (President/Secretary) for their authenticated groupId
 */
const getReportData = async (req, res) => {
  try {
    const { reportType } = req.params;
    const { month } = req.query; // YYYY-MM
    const { role, position, groupId: userGroupId } = req.user;

    // 1. Strict RBAC Enforcement
    const isLeader = role === "leader" || ["president", "secretary"].includes(position);
    if (!isLeader) {
      return res.status(403).json({
        success: false,
        message: "Forbidden: Only authorized group leaders can export group reports.",
      });
    }

    if (!userGroupId) {
      return res.status(400).json({
        success: false,
        message: "Group ID missing in user credentials.",
      });
    }

    // 2. Parse Date Window for Monthly Filtering
    let selectedMonth = month;
    if (!selectedMonth || !/^\d{4}-\d{2}$/.test(selectedMonth)) {
      const now = new Date();
      selectedMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
    }

    const [year, m] = selectedMonth.split("-").map(Number);
    const startDate = new Date(Date.UTC(year, m - 1, 1, 0, 0, 0));
    const endDate = new Date(Date.UTC(year, m, 1, 0, 0, 0));

    // Fetch all members in this group for fast name lookup
    const groupUsers = await User.find({ groupId: userGroupId }).lean();
    const userMap = new Map();
    groupUsers.forEach(u => userMap.set(u.userId, u.name));

    const now = new Date();

    // 3. Generate Specific Report Type
    switch (reportType) {
      case "monthly-collection": {
        const collections = await Transaction.find({
          groupId: userGroupId,
          type: "loan_payment",
          status: "completed",
          paymentDate: { $gte: startDate, $lt: endDate },
        }).sort({ paymentDate: -1 }).lean();

        let totalAmount = 0;
        const records = collections.map(t => {
          totalAmount += t.amount || 0;
          return {
            transactionId: t.transactionId || "",
            memberId: t.memberId || "",
            memberName: userMap.get(t.memberId) || "Member",
            paymentDate: t.paymentDate || t.createdAt,
            paymentType: t.notes || `EMI Installment #${t.installmentNumber || 1}`,
            amount: t.amount || 0,
            status: "Completed",
          };
        });

        return res.status(200).json({
          success: true,
          reportType: "monthly-collection",
          reportTitle: "Monthly Collection Report",
          groupId: userGroupId,
          reportingMonth: selectedMonth,
          generatedAt: now.toISOString(),
          summary: {
            totalAmount: Number(totalAmount.toFixed(2)),
            totalTransactions: records.length,
          },
          records,
        });
      }

      case "pending-emi": {
        const pendingEmis = await Emi.find({
          groupId: userGroupId,
          status: { $ne: "paid" },
        }).sort({ dueDate: 1 }).lean();

        let totalPendingAmount = 0;
        const records = pendingEmis.map(e => {
          totalPendingAmount += e.amount || 0;
          const due = new Date(e.dueDate);
          let currentStatus = e.status;
          if (due < now && currentStatus !== "paid") {
            currentStatus = "overdue";
          } else if (due.toDateString() === now.toDateString() && currentStatus !== "paid") {
            currentStatus = "due";
          } else if (due > now && currentStatus !== "paid") {
            currentStatus = "pending";
          }

          return {
            emiId: e.emiId || "",
            memberId: e.memberId || "",
            memberName: userMap.get(e.memberId) || "Member",
            loanId: e.loanId || "",
            installmentNumber: e.installmentNumber || 1,
            amount: e.amount || 0,
            dueDate: e.dueDate,
            status: currentStatus,
          };
        });

        return res.status(200).json({
          success: true,
          reportType: "pending-emi",
          reportTitle: "Pending EMI Report",
          groupId: userGroupId,
          generatedAt: now.toISOString(),
          summary: {
            totalPendingAmount: Number(totalPendingAmount.toFixed(2)),
            totalInstallments: records.length,
          },
          records,
        });
      }

      case "subsidy-records": {
        const subsidies = await Subsidy.find({
          groupId: userGroupId,
        }).sort({ createdAt: -1 }).lean();

        let totalAmount = 0;
        let receivedCount = 0;

        const records = subsidies.map(s => {
          totalAmount += s.amount || 0;
          if (s.status === "received") receivedCount++;

          return {
            subsidyId: s.subsidyId || "",
            memberId: s.memberId || "",
            memberName: userMap.get(s.memberId) || "Member",
            schemeName: s.schemeName || "Government Scheme",
            amount: s.amount || 0,
            status: s.status || "received",
            dateReceived: s.dateReceived || s.createdAt,
            description: s.description || "",
          };
        });

        return res.status(200).json({
          success: true,
          reportType: "subsidy-records",
          reportTitle: "Subsidy Records Report",
          groupId: userGroupId,
          generatedAt: now.toISOString(),
          summary: {
            totalAmount: Number(totalAmount.toFixed(2)),
            totalRecords: records.length,
            receivedCount,
          },
          records,
        });
      }

      case "recovery": {
        const loans = await Loan.find({ groupId: userGroupId }).lean();
        const allCompletedTxs = await Transaction.find({
          groupId: userGroupId,
          type: "loan_payment",
          status: "completed",
        }).lean();

        let groupLoanTotal = 0;
        let groupRepaidInPeriod = 0;
        let groupRepaidTotal = 0;

        const records = [];

        for (const u of groupUsers) {
          const userLoan = loans.find(l => l.memberId === u.userId);
          const loanPrincipal = userLoan ? (userLoan.principalAmount || 0) : 0;
          const userTxs = allCompletedTxs.filter(t => t.memberId === u.userId);

          const totalPaid = userTxs.reduce((sum, t) => sum + (t.amount || 0), 0);
          const periodPaid = userTxs
            .filter(t => new Date(t.paymentDate || t.createdAt) >= startDate && new Date(t.paymentDate || t.createdAt) < endDate)
            .reduce((sum, t) => sum + (t.amount || 0), 0);

          const outstanding = Math.max(0, loanPrincipal - totalPaid);

          groupLoanTotal += loanPrincipal;
          groupRepaidInPeriod += periodPaid;
          groupRepaidTotal += totalPaid;

          const lastTx = userTxs.length > 0 ? userTxs[userTxs.length - 1] : null;

          records.push({
            memberId: u.userId,
            memberName: u.name,
            loanAmount: loanPrincipal,
            repaidInPeriod: periodPaid,
            totalRepaidToDate: totalPaid,
            outstandingBalance: outstanding,
            lastPaymentDate: lastTx ? (lastTx.paymentDate || lastTx.createdAt) : null,
            lastTxReference: lastTx ? (lastTx.transactionId || "") : "N/A",
          });
        }

        const groupOutstandingTotal = Math.max(0, groupLoanTotal - groupRepaidTotal);

        return res.status(200).json({
          success: true,
          reportType: "recovery",
          reportTitle: "Group Loan Recovery Report",
          groupId: userGroupId,
          reportingMonth: selectedMonth,
          generatedAt: now.toISOString(),
          summary: {
            groupLoanTotal: Number(groupLoanTotal.toFixed(2)),
            groupRepaidInPeriod: Number(groupRepaidInPeriod.toFixed(2)),
            groupRepaidTotal: Number(groupRepaidTotal.toFixed(2)),
            groupOutstandingTotal: Number(groupOutstandingTotal.toFixed(2)),
          },
          records,
        });
      }

      default:
        return res.status(400).json({
          success: false,
          message: "Invalid report type requested.",
        });
    }
  } catch (error) {
    console.error("Get report error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to generate report data.",
    });
  }
};

module.exports = { getReportData };
