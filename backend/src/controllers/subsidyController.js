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
    res.status(500).json({ success: false, message: "Failed to fetch subsidies" });
  }
};

const createSubsidy = async (req, res) => {
  try {
    const {
      subsidyId,
      memberId,
      groupId,
      schemeName,
      amount,
      status,
      dateReceived,
      description,
    } = req.body;

    const { role, groupId: userGroupId } = req.user;

    if (role !== "leader") {
      return res.status(403).json({
        success: false,
        message: "Only group leaders can record subsidies",
      });
    }

    if (groupId !== userGroupId) {
      return res.status(403).json({
        success: false,
        message: "Cannot record subsidy for another group",
      });
    }

    if (!subsidyId || !memberId || !groupId || !schemeName || amount === undefined) {
      return res.status(400).json({
        success: false,
        message: "Required fields are missing",
      });
    }

    const existingSubsidy = await Subsidy.findOne({ subsidyId });
    if (existingSubsidy) {
      return res.status(409).json({
        success: false,
        message: "Subsidy ID already exists",
      });
    }

    const subsidy = await Subsidy.create({
      subsidyId,
      memberId,
      groupId,
      schemeName,
      amount,
      status,
      dateReceived,
      description,
    });

    res.status(201).json({
      success: true,
      message: "Subsidy created successfully",
      subsidy,
    });
  } catch (error) {
    console.error("Create subsidy error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to create subsidy",
    });
  }
};

module.exports = {
  getSubsidies,
  createSubsidy,
};
