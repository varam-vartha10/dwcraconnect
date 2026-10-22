const User = require("../models/User");
const Group = require("../models/Group");
const RegistrationRequest = require("../models/RegistrationRequest");

/**
 * 1. Get Leader Group Roster with Registration Statuses
 * Protected - Leader Only
 */
const getGroupRoster = async (req, res) => {
  try {
    const { groupId } = req.params;
    const { role, position, groupId: userGroupId } = req.user;

    const isLeader = role === "leader" || ["president", "secretary"].includes(position);
    if (!isLeader) {
      return res.status(403).json({
        success: false,
        message: "Forbidden: Only group leaders can manage member rosters.",
      });
    }

    if (groupId !== userGroupId) {
      return res.status(403).json({
        success: false,
        message: "Forbidden: Cannot access member roster of another group.",
      });
    }

    // Get all users in group
    const users = await User.find({ groupId }).select("-password").lean();
    const pendingReqs = await RegistrationRequest.find({ groupId, status: "pending_approval" }).lean();

    const group = await Group.findOne({ groupId }).lean();
    const maxMembers = group ? (group.maxMembers || 10) : 10;

    const roster = users.map(u => ({
      userId: u.userId,
      name: u.name,
      phoneNumber: u.phoneNumber || "Not Set",
      village: u.village || "N/A",
      role: u.role,
      position: u.position,
      status: u.password ? "Active" : "Not Registered",
      isRegistered: Boolean(u.password),
      mobileVerified: Boolean(u.mobileVerified),
      createdAt: u.createdAt,
    }));

    return res.status(200).json({
      success: true,
      groupId,
      groupName: group ? group.groupName : groupId,
      totalMembers: roster.length,
      maxMembers,
      pendingApprovalCount: pendingReqs.length,
      roster,
      pendingRequests: pendingReqs,
    });
  } catch (error) {
    console.error("Get group roster error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch group member roster.",
    });
  }
};

/**
 * 2. Add Existing Member to Roster by Leader
 * Protected - Leader Only
 */
const addRosterMember = async (req, res) => {
  try {
    const { groupId } = req.params;
    const { name, phoneNumber, memberId, village, position } = req.body;
    const { role, position: leaderPos, groupId: userGroupId } = req.user;

    const isLeader = role === "leader" || ["president", "secretary"].includes(leaderPos);
    if (!isLeader) {
      return res.status(403).json({
        success: false,
        message: "Forbidden: Only group leaders can pre-register group members.",
      });
    }

    if (groupId !== userGroupId) {
      return res.status(403).json({
        success: false,
        message: "Forbidden: Cannot add members to another group.",
      });
    }

    if (!name || !village) {
      return res.status(400).json({
        success: false,
        message: "Member Full Name and Village are required.",
      });
    }

    const group = await Group.findOne({ groupId });
    const maxMembers = group ? (group.maxMembers || 10) : 10;
    const currentMemberCount = await User.countDocuments({ groupId, isActive: true });

    if (currentMemberCount >= maxMembers) {
      return res.status(400).json({
        success: false,
        message: `Group '${groupId}' already has ${currentMemberCount} active members. Maximum limit of ${maxMembers} members reached.`,
      });
    }

    const cleanPhone = phoneNumber ? String(phoneNumber).trim().replace(/\D/g, "") : null;
    if (cleanPhone && cleanPhone.length === 10) {
      const existingUser = await User.findOne({ phoneNumber: cleanPhone });
      if (existingUser) {
        return res.status(409).json({
          success: false,
          message: `Phone number '${cleanPhone}' is already assigned to member ${existingUser.userId} (${existingUser.name}).`,
        });
      }
    }

    // Auto-generate memberId if not provided
    let assignedUserId = memberId ? String(memberId).trim() : null;
    if (!assignedUserId) {
      const totalUsers = await User.countDocuments();
      assignedUserId = `SHG-${String(totalUsers + 1).padStart(3, "0")}`;
    }

    // Collision check for memberId
    const existingId = await User.findOne({ userId: assignedUserId });
    if (existingId) {
      const totalUsers = await User.countDocuments();
      assignedUserId = `SHG-${String(totalUsers + 10).padStart(3, "0")}`;
    }

    // Pre-register member without setting password (isRegistered = false)
    const newUser = await User.create({
      userId: assignedUserId,
      groupId,
      name: String(name).trim(),
      phoneNumber: cleanPhone || `TEMP-${assignedUserId}`,
      password: "", // Unset until member performs self-activation
      role: "member",
      position: position || "member",
      village: String(village).trim(),
      isActive: true,
    });

    return res.status(201).json({
      success: true,
      message: `Member ${newUser.name} added to roster successfully. Assigned Member ID: ${newUser.userId}.`,
      member: {
        userId: newUser.userId,
        name: newUser.name,
        phoneNumber: newUser.phoneNumber,
        groupId: newUser.groupId,
        village: newUser.village,
        status: "Not Registered",
      },
    });
  } catch (error) {
    console.error("Add roster member error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to add member to group roster.",
    });
  }
};

/**
 * 3. Leader-Assisted Update of Registered Mobile Number
 * Protected - Leader Only
 */
const updateMemberMobile = async (req, res) => {
  try {
    const { groupId, userId } = req.params;
    const { newPhoneNumber } = req.body;
    const { role, position, groupId: userGroupId, userId: leaderUserId } = req.user;

    const isLeader = role === "leader" || ["president", "secretary"].includes(position);
    if (!isLeader) {
      return res.status(403).json({
        success: false,
        message: "Forbidden: Only authorized group leaders can update member mobile numbers.",
      });
    }

    if (groupId !== userGroupId) {
      return res.status(403).json({
        success: false,
        message: "Forbidden: Cannot update mobile numbers for another group.",
      });
    }

    const cleanPhone = String(newPhoneNumber).trim().replace(/\D/g, "");
    if (cleanPhone.length !== 10) {
      return res.status(400).json({
        success: false,
        message: "Invalid mobile number. Must be a 10-digit phone number.",
      });
    }

    // Duplicate Phone Check
    const existingUser = await User.findOne({ phoneNumber: cleanPhone, userId: { $ne: userId } });
    if (existingUser) {
      return res.status(409).json({
        success: false,
        message: `Mobile number ${cleanPhone} is already registered to another member (${existingUser.name}).`,
      });
    }

    const user = await User.findOne({ userId, groupId });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: "Member not found in this group.",
      });
    }

    user.phoneNumber = cleanPhone;
    user.mobileVerified = false; // Reset verification for new phone
    await user.save();

    console.log(`[Audit Trail] Leader ${leaderUserId} updated mobile number for member ${userId} (${user.name}) to ${cleanPhone} at ${new Date().toISOString()}`);

    return res.status(200).json({
      success: true,
      message: `Mobile number for ${user.name} (${userId}) updated to +91 ${cleanPhone}. The member can now perform self-service OTP verification.`,
      member: {
        userId: user.userId,
        name: user.name,
        phoneNumber: user.phoneNumber,
      },
    });
  } catch (error) {
    console.error("Update member mobile error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to update member mobile number.",
    });
  }
};

/**
 * 4. Bulk CSV/JSON Import Roster Members
 * Protected - Leader Only
 */
const bulkImportRoster = async (req, res) => {
  try {
    const { groupId } = req.params;
    const { members } = req.body; // Array of { name, phoneNumber, village }
    const { role, position, groupId: userGroupId } = req.user;

    const isLeader = role === "leader" || ["president", "secretary"].includes(position);
    if (!isLeader) {
      return res.status(403).json({
        success: false,
        message: "Forbidden: Only authorized group leaders can perform bulk member imports.",
      });
    }

    if (groupId !== userGroupId) {
      return res.status(403).json({
        success: false,
        message: "Forbidden: Cannot import members into another group.",
      });
    }

    if (!Array.isArray(members) || members.length === 0) {
      return res.status(400).json({
        success: false,
        message: "Please provide a non-empty array of members to import.",
      });
    }

    const group = await Group.findOne({ groupId });
    const maxMembers = group ? (group.maxMembers || 10) : 10;
    const currentMemberCount = await User.countDocuments({ groupId, isActive: true });

    if (currentMemberCount + members.length > maxMembers) {
      return res.status(400).json({
        success: false,
        message: `Import failed: Adding ${members.length} members exceeds group maximum capacity of ${maxMembers} (Current: ${currentMemberCount}).`,
      });
    }

    let addedCount = 0;
    const addedMembers = [];

    for (const item of members) {
      if (!item.name || !item.village) continue;

      const cleanPhone = item.phoneNumber ? String(item.phoneNumber).trim().replace(/\D/g, "") : null;
      if (cleanPhone && cleanPhone.length === 10) {
        const exists = await User.findOne({ phoneNumber: cleanPhone });
        if (exists) continue; // Skip duplicates
      }

      const totalUsers = await User.countDocuments();
      const assignedUserId = `SHG-${String(totalUsers + 1).padStart(3, "0")}`;

      const newUser = await User.create({
        userId: assignedUserId,
        groupId,
        name: String(item.name).trim(),
        phoneNumber: cleanPhone || `TEMP-${assignedUserId}`,
        password: "",
        role: "member",
        position: "member",
        village: String(item.village).trim(),
        isActive: true,
      });

      addedCount++;
      addedMembers.push({ userId: newUser.userId, name: newUser.name, phoneNumber: newUser.phoneNumber });
    }

    return res.status(200).json({
      success: true,
      addedCount,
      message: `Successfully imported ${addedCount} member(s) into group ${groupId}.`,
      members: addedMembers,
    });
  } catch (error) {
    console.error("Bulk import roster error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to perform bulk member import.",
    });
  }
};

module.exports = {
  getGroupRoster,
  addRosterMember,
  updateMemberMobile,
  bulkImportRoster,
};
