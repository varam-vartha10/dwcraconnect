const Group = require("../models/Group");
const User = require("../models/User");
const RegistrationRequest = require("../models/RegistrationRequest");

const getGroups = async (req, res) => {
  try {
    const groups = await Group.find().lean();

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

/**
 * GET /api/groups/:groupId/pending-registrations
 * Protected - Leader Only
 */
const getPendingRegistrations = async (req, res) => {
  try {
    const { groupId } = req.params;
    const { role, position, groupId: userGroupId } = req.user;

    const isLeader = role === "leader" || ["president", "secretary"].includes(position);
    if (!isLeader) {
      return res.status(403).json({
        success: false,
        message: "Forbidden: Only authorized group leaders can view pending registrations.",
      });
    }

    if (groupId !== userGroupId) {
      return res.status(403).json({
        success: false,
        message: "Forbidden: Cannot access pending registrations for another group.",
      });
    }

    const pendingRequests = await RegistrationRequest.find({
      groupId,
      status: "pending_approval",
    }).sort({ createdAt: -1 }).lean();

    return res.status(200).json({
      success: true,
      count: pendingRequests.length,
      pendingRequests,
    });
  } catch (error) {
    console.error("Get pending registrations error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch pending registrations.",
    });
  }
};

/**
 * POST /api/groups/:groupId/approve-registration
 * Protected - Leader Only
 */
const approveRegistration = async (req, res) => {
  try {
    const { groupId } = req.params;
    const { registrationId, action, rejectionReason } = req.body;
    const { role, position, groupId: userGroupId, userId: leaderUserId } = req.user;

    const isLeader = role === "leader" || ["president", "secretary"].includes(position);
    if (!isLeader) {
      return res.status(403).json({
        success: false,
        message: "Forbidden: Only authorized group leaders can approve member registrations.",
      });
    }

    if (groupId !== userGroupId) {
      return res.status(403).json({
        success: false,
        message: "Forbidden: Cannot process registration approval for another group.",
      });
    }

    if (!registrationId || !action) {
      return res.status(400).json({
        success: false,
        message: "registrationId and action ('approve' or 'reject') are required.",
      });
    }

    const regRequest = await RegistrationRequest.findOne({
      registrationId,
      groupId,
      status: "pending_approval",
    });

    if (!regRequest) {
      return res.status(404).json({
        success: false,
        message: "Pending registration request not found.",
      });
    }

    if (action === "reject") {
      regRequest.status = "rejected";
      regRequest.rejectionReason = rejectionReason || "Registration rejected by group leader.";
      await regRequest.save();

      return res.status(200).json({
        success: true,
        message: `Registration for ${regRequest.fullName} has been rejected.`,
      });
    }

    if (action === "approve") {
      // Enforce 10-Member Group Limit Guard
      const group = await Group.findOne({ groupId });
      const maxMembers = group ? (group.maxMembers || 10) : 10;
      const activeMemberCount = await User.countDocuments({ groupId, isActive: true });

      if (activeMemberCount >= maxMembers) {
        return res.status(400).json({
          success: false,
          message: `Cannot approve member: Group '${groupId}' already has ${activeMemberCount} active members. Maximum limit of ${maxMembers} reached.`,
        });
      }

      // Generate or confirm unique member ID
      let assignedMemberId = regRequest.assignedMemberId;
      if (!assignedMemberId) {
        const totalUsers = await User.countDocuments();
        assignedMemberId = `SHG-${String(totalUsers + 1).padStart(3, "0")}`;
      }

      // Check for user collision
      const existingUser = await User.findOne({ userId: assignedMemberId });
      if (existingUser) {
        const totalUsers = await User.countDocuments();
        assignedMemberId = `SHG-${String(totalUsers + 10).padStart(3, "0")}`;
      }

      // Create official User document in User collection
      await User.create({
        userId: assignedMemberId,
        groupId: regRequest.groupId,
        name: regRequest.fullName,
        phoneNumber: regRequest.phoneNumber,
        password: regRequest.passwordHash,
        role: "member",
        position: regRequest.requestedRole || "member",
        village: regRequest.village,
        isActive: true,
      });

      // Update Registration Request status
      regRequest.status = "approved";
      regRequest.approvedBy = leaderUserId;
      regRequest.assignedMemberId = assignedMemberId;
      await regRequest.save();

      return res.status(200).json({
        success: true,
        assignedMemberId,
        message: `Member '${regRequest.fullName}' approved successfully! Assigned Member ID: ${assignedMemberId}.`,
      });
    }

    return res.status(400).json({
      success: false,
      message: "Invalid action specified. Must be 'approve' or 'reject'.",
    });
  } catch (error) {
    console.error("Approve registration error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to process registration approval.",
    });
  }
};

module.exports = {
  getGroups,
  createGroup,
  getPendingRegistrations,
  approveRegistration,
};
