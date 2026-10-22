const bcrypt = require("bcryptjs");
const crypto = require("crypto");
const User = require("../models/User");
const Group = require("../models/Group");
const Otp = require("../models/Otp");
const RegistrationRequest = require("../models/RegistrationRequest");
const AuditLog = require("../models/AuditLog");
const { sendOtp } = require("../services/smsService");

function hashOtp(otp) {
  return crypto.createHash("sha256").update(String(otp)).digest("hex");
}

function maskPhone(phone) {
  if (!phone || phone.length < 4) return "Not Set";
  return `+91 XXXXX ${phone.slice(-4)}`;
}

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
      phoneNumberMasked: maskPhone(u.phoneNumber),
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
    const { role, position: leaderPos, groupId: userGroupId, userId: leaderUserId } = req.user;

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
          message: `Phone number '${maskPhone(cleanPhone)}' is already assigned to member ${existingUser.userId} (${existingUser.name}).`,
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

    // Audit Log Entry
    await AuditLog.create({
      memberId: assignedUserId,
      groupId,
      actingLeaderId: leaderUserId,
      action: "LEADER_PRE_REGISTERED_MEMBER",
      phoneNumberMasked: cleanPhone ? maskPhone(cleanPhone) : "N/A",
      details: `Pre-registered member ${newUser.name} into group ${groupId}`,
      physicalRegisterChecked: true,
    });

    return res.status(201).json({
      success: true,
      message: `Member ${newUser.name} added to roster successfully. Assigned Member ID: ${newUser.userId}.`,
      member: {
        userId: newUser.userId,
        name: newUser.name,
        phoneNumberMasked: maskPhone(newUser.phoneNumber),
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
 * 3. Leader-Assisted Identity Verification & Mobile Number Update
 * Protected - Leader Only
 */
const verifyMemberIdentityAndMobile = async (req, res) => {
  try {
    const { groupId, userId } = req.params;
    const { newPhoneNumber, physicalRegisterChecked } = req.body;
    const { role, position, groupId: userGroupId, userId: leaderUserId } = req.user;

    const isLeader = role === "leader" || ["president", "secretary"].includes(position);
    if (!isLeader) {
      return res.status(403).json({
        success: false,
        message: "Forbidden: Only authorized group leaders can verify member identities.",
      });
    }

    if (groupId !== userGroupId) {
      return res.status(403).json({
        success: false,
        message: "Forbidden: Cannot verify members from another group.",
      });
    }

    if (!physicalRegisterChecked) {
      return res.status(400).json({
        success: false,
        message: "Leader confirmation required: You must confirm checking the member's identity against the physical SHG register.",
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
        message: `Mobile number '${maskPhone(cleanPhone)}' is already registered to member ${existingUser.userId} (${existingUser.name}). Requires authorized resolution.`,
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
    user.mobileVerified = false; // Reset verification so member MUST enter OTP herself
    await user.save();

    // Create Audit Log
    await AuditLog.create({
      memberId: userId,
      groupId,
      actingLeaderId: leaderUserId,
      action: "LEADER_VERIFIED_MEMBER_MOBILE_UPDATE",
      phoneNumberMasked: maskPhone(cleanPhone),
      details: `Leader ${leaderUserId} verified physical SHG register and updated mobile number for ${user.name} (${userId})`,
      physicalRegisterChecked: true,
    });

    // Send Real OTP to newly submitted mobile number
    const rawOtp = String(Math.floor(100000 + Math.random() * 900000));
    const otpHash = hashOtp(rawOtp);
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

    await Otp.deleteMany({ phoneNumber: cleanPhone });
    await Otp.create({
      phoneNumber: cleanPhone,
      otpHash,
      attempts: 0,
      expiresAt,
    });

    // Save/Update Registration Request for member self-activation
    const activationId = `ACT-${Date.now()}-${Math.floor(1000 + Math.random() * 9000)}`;
    await RegistrationRequest.deleteMany({ phoneNumber: cleanPhone });
    await RegistrationRequest.create({
      registrationId: activationId,
      fullName: user.name,
      phoneNumber: cleanPhone,
      village: user.village || "N/A",
      mandal: "N/A",
      district: "N/A",
      groupId: user.groupId,
      assignedMemberId: user.userId,
      status: "pending_otp",
    });

    const smsResult = await sendOtp(cleanPhone, rawOtp);

    return res.status(200).json({
      success: true,
      activationId,
      message: `Member identity verified for ${user.name} (${userId}). OTP sent to ${maskPhone(cleanPhone)}. The member can now enter her OTP and create her password.`,
      smsGatewayStatus: smsResult.provider,
    });
  } catch (error) {
    console.error("Verify member identity error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to verify member identity.",
    });
  }
};

/**
 * 4. Supervised Alternative In-Person Member Activation (Feature phones / No SMS)
 * Protected - Leader Only
 */
const supervisedInPersonActivation = async (req, res) => {
  try {
    const { groupId, userId } = req.params;
    const { password, confirmPassword, physicalRegisterChecked } = req.body;
    const { role, position, groupId: userGroupId, userId: leaderUserId } = req.user;

    const isLeader = role === "leader" || ["president", "secretary"].includes(position);
    if (!isLeader) {
      return res.status(403).json({
        success: false,
        message: "Forbidden: Only authorized group leaders can perform supervised activations.",
      });
    }

    if (groupId !== userGroupId) {
      return res.status(403).json({
        success: false,
        message: "Forbidden: Cannot perform supervised activation for another group.",
      });
    }

    if (!physicalRegisterChecked) {
      return res.status(400).json({
        success: false,
        message: "Leader confirmation required: You must confirm checking member's identity against physical SHG register.",
      });
    }

    if (!password || password !== confirmPassword || String(password).length < 6) {
      return res.status(400).json({
        success: false,
        message: "Member's chosen password must be at least 6 characters long and match confirmation.",
      });
    }

    const user = await User.findOne({ userId, groupId });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: "Member not found in this group.",
      });
    }

    // Hash member's password using bcrypt salt rounds 12
    const salt = await bcrypt.genSalt(12);
    user.password = await bcrypt.hash(password, salt);
    user.isActive = true;
    await user.save();

    // Audit Log Entry
    await AuditLog.create({
      memberId: userId,
      groupId,
      actingLeaderId: leaderUserId,
      action: "LEADER_SUPERVISED_IN_PERSON_ACTIVATION",
      phoneNumberMasked: maskPhone(user.phoneNumber),
      details: `Supervised in-person activation completed for ${user.name} (${userId}) by Leader ${leaderUserId}`,
      physicalRegisterChecked: true,
    });

    return res.status(200).json({
      success: true,
      message: `Supervised in-person activation completed for ${user.name} (${userId}). Account is now active.`,
    });
  } catch (error) {
    console.error("Supervised activation error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to perform supervised in-person activation.",
    });
  }
};

/**
 * 5. Bulk CSV/JSON Import Roster Members
 * Protected - Leader Only
 */
const bulkImportRoster = async (req, res) => {
  try {
    const { groupId } = req.params;
    const { members } = req.body;
    const { role, position, groupId: userGroupId, userId: leaderUserId } = req.user;

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
        if (exists) continue;
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
      addedMembers.push({ userId: newUser.userId, name: newUser.name, phoneNumberMasked: maskPhone(newUser.phoneNumber) });
    }

    // Audit Log Entry
    await AuditLog.create({
      memberId: `BULK-${addedCount}`,
      groupId,
      actingLeaderId: leaderUserId,
      action: "LEADER_BULK_ROSTER_IMPORT",
      details: `Bulk imported ${addedCount} member(s) into group ${groupId}`,
      physicalRegisterChecked: true,
    });

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
  verifyMemberIdentityAndMobile,
  supervisedInPersonActivation,
  bulkImportRoster,
};
