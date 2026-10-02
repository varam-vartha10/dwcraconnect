const { getMyAccountSummary } = require("../services/accountSummaryService");
const { getGroupSummary } = require("../services/groupSummaryService");

// 1. Personal Account Summary
const getPersonalAccountSummary = async (req, res) => {
  try {
    const { userId, groupId, role } = req.user;
    const summary = await getMyAccountSummary(userId, groupId, role);

    res.status(200).json({
      success: true,
      summary,
    });
  } catch (error) {
    console.error("Get personal account summary error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch account summary",
    });
  }
};

// 2. Group Financial Summary (Leader/Secretary Only)
const getGroupFinancialSummary = async (req, res) => {
  try {
    const { groupId } = req.params;
    const { role, position, groupId: userGroupId } = req.user;

    // RBAC: Verify user belongs to the requested group and is a Leader/President/Secretary
    if (groupId !== userGroupId) {
      return res.status(403).json({
        success: false,
        message: "Forbidden: Cannot access financial summary of another group",
      });
    }

    if (role !== "leader" && !["president", "secretary"].includes(position)) {
      return res.status(403).json({
        success: false,
        message: "Forbidden: Only group leaders can access group financial summary",
      });
    }

    const groupSummary = await getGroupSummary(groupId);

    res.status(200).json({
      success: true,
      summary: groupSummary,
    });
  } catch (error) {
    console.error("Get group summary error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch group financial summary",
    });
  }
};

// 3. Member Breakdown Financial Summary (Leader/Secretary Only)
const getGroupMembersFinancialSummary = async (req, res) => {
  try {
    const { groupId } = req.params;
    const { role, position, groupId: userGroupId } = req.user;

    if (groupId !== userGroupId) {
      return res.status(403).json({
        success: false,
        message: "Forbidden: Cannot access financial summary of another group",
      });
    }

    if (role !== "leader" && !["president", "secretary"].includes(position)) {
      return res.status(403).json({
        success: false,
        message: "Forbidden: Only group leaders can access member breakdown",
      });
    }

    const groupSummary = await getGroupSummary(groupId);

    res.status(200).json({
      success: true,
      members: groupSummary.memberSummaries,
    });
  } catch (error) {
    console.error("Get member breakdown error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch member financial breakdown",
    });
  }
};

module.exports = {
  getPersonalAccountSummary,
  getGroupFinancialSummary,
  getGroupMembersFinancialSummary,
};
