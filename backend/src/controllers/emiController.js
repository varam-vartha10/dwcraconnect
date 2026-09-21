const Emi = require("../models/Emi");

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

module.exports = { getEmis };
