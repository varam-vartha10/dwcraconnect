const Subsidy = require("../models/Subsidy");

const getSubsidies = async (req, res) => {
  try {
    const { memberId } = req.query;
    const { role, groupId: userGroupId, userId } = req.user;

    const filter = { groupId: userGroupId };

    if (role === "member") {
      filter.memberId = userId;
    } else if (role === "leader" && memberId) {
      filter.memberId = memberId;
    }

    const subsidies = await Subsidy.find(filter).sort({ createdAt: -1 }).lean();

    res.status(200).json({
      success: true,
      count: subsidies.length,
      subsidies,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: "Failed" });
  }
};

module.exports = { getSubsidies };
