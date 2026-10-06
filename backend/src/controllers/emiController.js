const Emi = require("../models/Emi");
const { processEmiPayment, getEmiSummary } = require("../services/financialService");

const getEmis = async (req, res) => {
  try {
    const { loanId, memberId, status } = req.query;
    const { role, groupId: userGroupId, userId } = req.user;

    const filter = { groupId: userGroupId };

    if (role === "member") {
      filter.memberId = userId;
    } else if (role === "leader") {
      if (memberId) filter.memberId = memberId;
      if (loanId) filter.loanId = loanId;
    }

    if (status) filter.status = status;

    const summary = await getEmiSummary(role === "member" ? userId : (memberId || userId));

    res.status(200).json({
      success: true,
      count: summary.emis.length,
      emis: summary.emis,
      overdueCount: summary.overdueEmisCount,
      nextEmi: summary.nextUpcomingEmi,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch EMI records",
    });
  }
};

const payEmi = async (req, res) => {
  try {
    const { emiId, amount, notes } = req.body;
    const { userId, groupId, role } = req.user;

    if (!emiId) {
      return res.status(400).json({ success: false, message: "emiId is required" });
    }

    const result = await processEmiPayment({
      memberId: userId,
      groupId,
      emiId,
      amount,
      paymentDate: new Date(),
      notes,
      userRole: role,
    });

    res.status(200).json({
      success: true,
      message: result.message,
      emi: result.emi,
      transaction: result.transaction,
      remainingBalance: result.remainingBalance,
      totalPaid: result.totalPaid,
      nextEmi: result.nextEmi,
      unpaidEmisCount: result.unpaidEmisCount,
    });
  } catch (error) {
    console.error("Pay EMI error:", error.message);
    const statusCode = error.message.includes("Unauthorized") ? 403 : 400;
    res.status(statusCode).json({
      success: false,
      message: error.message || "Failed to process EMI payment",
    });
  }
};

module.exports = { getEmis, payEmi };
