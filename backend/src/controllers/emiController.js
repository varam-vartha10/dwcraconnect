const Emi = require("../models/Emi");
const { processEmiPayment } = require("../services/financialService");

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

    const emis = await Emi.find(filter).sort({ dueDate: 1 }).lean();

    res.status(200).json({
      success: true,
      count: emis.length,
      emis,
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
    const { userId, groupId } = req.user;

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
    });

    res.status(200).json({
      success: true,
      message: "EMI payment recorded successfully",
      emi: result.emi,
      transaction: result.transaction,
    });
  } catch (error) {
    console.error("Pay EMI error:", error.message);
    res.status(400).json({
      success: false,
      message: error.message || "Failed to process EMI payment",
    });
  }
};

module.exports = { getEmis, payEmi };
