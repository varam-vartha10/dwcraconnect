const bcrypt = require("bcryptjs");
const crypto = require("crypto");
const User = require("../models/User");
const Group = require("../models/Group");
const Otp = require("../models/Otp");
const RegistrationRequest = require("../models/RegistrationRequest");
const { sendOtp } = require("../services/smsService");

function hashOtp(otp) {
  return crypto.createHash("sha256").update(String(otp)).digest("hex");
}

/**
 * 1. Initiate First-Time Member Self-Service Activation
 */
const initiateActivation = async (req, res) => {
  try {
    const { identifier } = req.body;

    if (!identifier || String(identifier).trim().isEmpty) {
      return res.status(400).json({
        success: false,
        message: "Please enter your Member ID (e.g. SHG-004) or registered 10-digit mobile number.",
      });
    }

    const cleanInput = String(identifier).trim();
    const cleanPhone = cleanInput.replace(/\D/g, "");

    // Search User collection by Member ID or Phone Number
    let user = await User.findOne({
      $or: [
        { userId: cleanInput.toUpperCase() },
        { userId: cleanInput },
        { phoneNumber: cleanPhone },
        { mobile: cleanPhone },
      ],
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: `Member record '${cleanInput}' not found. Please ask your group President or Secretary to add you to the group member roster first.`,
      });
    }

    // Check if user is ALREADY active with a set password
    if (user.password && user.password.length > 0) {
      return res.status(400).json({
        success: false,
        message: `Account for ${user.name} (${user.userId}) is already active. Please log in directly using your mobile number and password.`,
      });
    }

    // Check if phone number is valid
    if (!user.phoneNumber || user.phoneNumber.startsWith("TEMP-") || user.phoneNumber.length !== 10) {
      return res.status(400).json({
        success: false,
        message: `No valid mobile number is registered for ${user.name} (${user.userId}). Please ask your group President or Secretary to update your mobile number in the 'Manage Members' section.`,
      });
    }

    const activationId = `ACT-${Date.now()}-${Math.floor(1000 + Math.random() * 9000)}`;
    const rawOtp = String(Math.floor(100000 + Math.random() * 900000));
    const otpHash = hashOtp(rawOtp);
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

    await Otp.deleteMany({ phoneNumber: user.phoneNumber });
    await Otp.create({
      phoneNumber: user.phoneNumber,
      otpHash,
      attempts: 0,
      expiresAt,
    });

    await RegistrationRequest.deleteMany({ phoneNumber: user.phoneNumber });
    await RegistrationRequest.create({
      registrationId: activationId,
      fullName: user.name,
      phoneNumber: user.phoneNumber,
      village: user.village || "N/A",
      mandal: "N/A",
      district: "N/A",
      groupId: user.groupId,
      assignedMemberId: user.userId,
      status: "pending_otp",
    });

    const smsResult = await sendOtp(user.phoneNumber, rawOtp);
    const maskedPhone = `+91 XXXXX ${user.phoneNumber.slice(-4)}`;

    return res.status(200).json({
      success: true,
      activationId,
      userId: user.userId,
      name: user.name,
      phoneNumber: user.phoneNumber,
      maskedPhone,
      message: `OTP sent successfully to registered mobile number ${maskedPhone}.`,
      smsGatewayStatus: smsResult.provider,
    });
  } catch (error) {
    console.error("Initiate activation error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to initiate member activation. Please try again.",
    });
  }
};

/**
 * 2. Verify Activation OTP
 */
const verifyActivationOtp = async (req, res) => {
  try {
    const { activationId, otp } = req.body;

    if (!activationId || !otp) {
      return res.status(400).json({
        success: false,
        message: "Activation ID and OTP are required.",
      });
    }

    const regReq = await RegistrationRequest.findOne({ registrationId: activationId });
    if (!regReq) {
      return res.status(404).json({
        success: false,
        message: "Activation session expired or invalid. Please start again.",
      });
    }

    const otpRecord = await Otp.findOne({ phoneNumber: regReq.phoneNumber });
    if (!otpRecord) {
      return res.status(400).json({
        success: false,
        message: "OTP expired or not found. Please request a new OTP.",
      });
    }

    if (otpRecord.attempts >= 3) {
      await Otp.deleteOne({ _id: otpRecord._id });
      return res.status(429).json({
        success: false,
        message: "Too many incorrect attempts. Please request a new OTP.",
      });
    }

    const submittedHash = hashOtp(String(otp).trim());
    if (submittedHash !== otpRecord.otpHash) {
      otpRecord.attempts += 1;
      await otpRecord.save();
      return res.status(400).json({
        success: false,
        message: `Invalid OTP. ${3 - otpRecord.attempts} attempts remaining.`,
      });
    }

    await Otp.deleteOne({ _id: otpRecord._id });
    regReq.mobileVerified = true;
    regReq.status = "pending_password";
    await regReq.save();

    return res.status(200).json({
      success: true,
      activationId: regReq.registrationId,
      message: "Mobile number verified successfully! Please create your password.",
    });
  } catch (error) {
    console.error("Verify activation OTP error:", error);
    return res.status(500).json({
      success: false,
      message: "Activation OTP verification failed.",
    });
  }
};

/**
 * 3. Complete Activation & Create Password
 */
const completeActivation = async (req, res) => {
  try {
    const { activationId, password, confirmPassword } = req.body;

    if (!activationId || !password || !confirmPassword) {
      return res.status(400).json({
        success: false,
        message: "Activation ID, Password, and Confirm Password are required.",
      });
    }

    if (password !== confirmPassword) {
      return res.status(400).json({
        success: false,
        message: "Password and Confirm Password do not match.",
      });
    }

    if (String(password).length < 6) {
      return res.status(400).json({
        success: false,
        message: "Password must be at least 6 characters long.",
      });
    }

    const regReq = await RegistrationRequest.findOne({ registrationId: activationId });
    if (!regReq || !regReq.mobileVerified) {
      return res.status(400).json({
        success: false,
        message: "Activation session invalid or mobile number not verified.",
      });
    }

    const user = await User.findOne({ userId: regReq.assignedMemberId });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: "Member record not found.",
      });
    }

    // Hash Password with bcrypt salt rounds 12
    const salt = await bcrypt.genSalt(12);
    user.password = await bcrypt.hash(password, salt);
    user.isActive = true;
    await user.save();

    regReq.status = "approved";
    await regReq.save();

    return res.status(200).json({
      success: true,
      userId: user.userId,
      name: user.name,
      phoneNumber: user.phoneNumber,
      message: `Account activated successfully for ${user.name} (${user.userId})! You can now log in using your mobile number and password.`,
    });
  } catch (error) {
    console.error("Complete activation error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to complete account activation.",
    });
  }
};

module.exports = {
  initiateActivation,
  verifyActivationOtp,
  completeActivation,
};
