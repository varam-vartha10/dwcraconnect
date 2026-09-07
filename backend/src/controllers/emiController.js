const Emi = require("../models/Emi");

const getEmis = async (req, res) => {
  try {
    const { loanId, memberId, groupId, status } = req.query;
    const { role, groupId: userGroupId, userId } = req.user;

    const filter = {};

    // 1. Enforce Group Access
    // Both leaders and members can only see EMIs from their own group
    filter.groupId = userGroupId;

    // 2. Enforce Member Access
    // Normal members can ONLY see their own EMI records
    if (role === "member") {
      filter.memberId = userId;
    } else if (role === "leader") {
      // Leaders can optionally filter by member or loan, but only within their group
      if (memberId) filter.memberId = memberId;
      if (loanId) filter.loanId = loanId;
    }

    // Apply additional filters from query if they don't violate roles
    if (status) filter.status = status;

    const emis = await Emi.find(filter).sort({ dueDate: 1 });

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
