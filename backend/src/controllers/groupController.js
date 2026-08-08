const Group = require("../models/Group");

const getGroups = async (req, res) => {
  try {
    const groups = await Group.find();

    res.status(200).json({
      success: true,
      count: groups.length,
      groups,
    });
  } catch (error) {
    console.error("Get groups error:", error);

    res.status(500).json({
      success: false,
      message: "Failed to fetch groups",
    });
  }
};

const createGroup = async (req, res) => {
  try {
    const {
      groupId,
      groupName,
      village,
      mandal,
      district,
      state,
    } = req.body;

    if (!groupId || !groupName) {
      return res.status(400).json({
        success: false,
        message: "groupId and groupName are required",
      });
    }

    const existingGroup = await Group.findOne({ groupId });

    if (existingGroup) {
      return res.status(409).json({
        success: false,
        message: "Group ID already exists",
      });
    }

    const group = await Group.create({
      groupId,
      groupName,
      village,
      mandal,
      district,
      state,
    });

    res.status(201).json({
      success: true,
      message: "Group created successfully",
      group,
    });
  } catch (error) {
    console.error("Create group error:", error);

    res.status(500).json({
      success: false,
      message: "Failed to create group",
    });
  }
};

module.exports = {
  getGroups,
  createGroup,
};