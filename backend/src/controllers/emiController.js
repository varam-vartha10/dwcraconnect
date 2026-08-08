const Emi = require("../models/Emi");

const getEmis = async (req, res) => {
  try {
    const {
      loanId,
      memberId,
      groupId,
      status,
    } = req.query;

    const filter = {};

    if (loanId) {
      filter.loanId = loanId;
    }

    if (memberId) {
      filter.memberId = memberId;
    }

    if (groupId) {
      filter.groupId = groupId;
    }

    if (status) {
      filter.status = status;
    }

    const emis = await Emi.find(filter).sort({
      dueDate: 1,
    });

    res.status(200).json({
      success: true,
      count: emis.length,
      emis,
    });
  } catch (error) {
    console.error("Get EMI error:", error);

    res.status(500).json({
      success: false,
      message: "Failed to fetch EMI records",
    });
  }
};

module.exports = {
  getEmis,
};