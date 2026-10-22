const bcrypt = require("bcryptjs");
const crypto = require("crypto");
const User = require("../models/User");
const Group = require("../models/Group");
const Otp = require("../models/Otp");
const RegistrationRequest = require("../models/RegistrationRequest");
const { sendOtp } = require("../services/smsService");

/**
 * Helper to generate SHA256 OTP Hash
 */
function hashOtp(otp) {
  return crypto.createHash("sha256").update(String(otp)).digest("hex");
}

/**
 * 1. Initiate Registration & Send Mobile OTP
 */
const initiateRegistration = async (req, res) => {
  try {
    const {
      fullName,
      phoneNumber,
      altPhoneNumber,
      dob,
      village,
      mandal,
      district,
      state,
      preferredLanguage,
      groupId,
      requestedRole,
      initialFinancials,
    } = req.body;

    // Validate Required Fields
    if (!fullName || !phoneNumber || !village || !mandal || !district || !groupId) {
      return res.status(400).json({
        success: false,
        message: "Required fields missing: Full Name, Phone Number, Village, Mandal, District, and Group ID are required.",
      });
    }

    const cleanPhone = String(phoneNumber).trim().replace(/\D/g, "");
    if (cleanPhone.length !== 10) {
      return res.status(400).json({
        success: false,
        message: "Invalid mobile number. Please provide a 10-digit mobile number.",
      });
    }

    // Check if user is already an active member in User collection
    const existingUser = await User.findOne({
      $or: [{ phoneNumber: cleanPhone }, { mobile: cleanPhone }],
    });

    if (existingUser) {
      return res.status(409).json({
        success: false,
        message: "This mobile number is already registered. Please log in.",
      });
    }

    // Verify Group Exists
    const group = await Group.findOne({ groupId: String(groupId).trim() });
    if (!group) {
      return res.status(404).json({
        success: false,
        message: `Group ID '${groupId}' not found. Please verify the group ID or request new group creation.`,
      });
    }

    // Generate unique Registration ID
    const registrationId = `REG-${Date.now()}-${Math.floor(1000 + Math.random() * 9000)}`;

    // Generate 6-digit OTP
    const rawOtp = String(Math.floor(100000 + Math.random() * 900000));
    const otpHash = hashOtp(rawOtp);
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes expiry

    // Save/Update OTP record
    await Otp.deleteMany({ phoneNumber: cleanPhone });
    await Otp.create({
      phoneNumber: cleanPhone,
      otpHash,
      attempts: 0,
      expiresAt,
    });

    // Save/Update Registration Request
    await RegistrationRequest.deleteMany({ phoneNumber: cleanPhone, status: { $ne: "approved" } });

    await RegistrationRequest.create({
      registrationId,
      fullName: String(fullName).trim(),
      phoneNumber: cleanPhone,
      altPhoneNumber: altPhoneNumber ? String(altPhoneNumber).trim() : null,
      dob: dob || null,
      village: String(village).trim(),
      mandal: String(mandal).trim(),
      district: String(district).trim(),
      state: state || "Andhra Pradesh",
      preferredLanguage: preferredLanguage || "en",
      groupId: group.groupId,
      requestedRole: requestedRole || "member",
      initialFinancials: {
        hasLoan: Boolean(initialFinancials?.hasLoan),
        provider: initialFinancials?.provider || null,
        accountNumber: initialFinancials?.accountNumber || null,
        originalAmount: initialFinancials?.originalAmount ? Number(initialFinancials.originalAmount) : null,
        outstandingBalance: initialFinancials?.outstandingBalance ? Number(initialFinancials.outstandingBalance) : null,
        emiAmount: initialFinancials?.emiAmount ? Number(initialFinancials.emiAmount) : null,
        emiFrequency: initialFinancials?.emiFrequency || "monthly",
        nextEmiDueDate: initialFinancials?.nextEmiDueDate || null,
        totalInstallments: initialFinancials?.totalInstallments ? Number(initialFinancials.totalInstallments) : null,
        paidInstallments: initialFinancials?.paidInstallments ? Number(initialFinancials.paidInstallments) : null,
        loanStartDate: initialFinancials?.loanStartDate || null,
        hasSubsidy: Boolean(initialFinancials?.hasSubsidy),
        subsidyAmount: initialFinancials?.subsidyAmount ? Number(initialFinancials.subsidyAmount) : null,
        isVerified: false,
      },
      status: "pending_otp",
    });

    // Send Real SMS OTP
    const smsResult = await sendOtp(cleanPhone, rawOtp);

    return res.status(200).json({
      success: true,
      registrationId,
      phoneNumber: cleanPhone,
      message: `OTP sent successfully to +91 ${cleanPhone}.`,
      smsGatewayStatus: smsResult.provider,
    });
  } catch (error) {
    console.error("Initiate registration error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to initiate registration. Please try again.",
    });
  }
};

/**
 * 2. Verify Mobile Number OTP
 */
const verifyOtp = async (req, res) => {
  try {
    const { registrationId, otp } = req.body;

    if (!registrationId || !otp) {
      return res.status(400).json({
        success: false,
        message: "Registration ID and OTP are required.",
      });
    }

    const regRequest = await RegistrationRequest.findOne({ registrationId });
    if (!regRequest) {
      return res.status(404).json({
        success: false,
        message: "Registration session not found or expired.",
      });
    }

    const otpRecord = await Otp.findOne({ phoneNumber: regRequest.phoneNumber });
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

    // OTP Verified Successfully
    await Otp.deleteOne({ _id: otpRecord._id });

    regRequest.mobileVerified = true;
    regRequest.status = "pending_password";
    await regRequest.save();

    return res.status(200).json({
      success: true,
      registrationId: regRequest.registrationId,
      message: "Mobile number verified successfully. Please create your password.",
    });
  } catch (error) {
    console.error("Verify OTP error:", error);
    return res.status(500).json({
      success: false,
      message: "OTP verification failed. Please try again.",
    });
  }
};

/**
 * 3. Resend Mobile OTP
 */
const resendOtp = async (req, res) => {
  try {
    const { registrationId } = req.body;

    const regRequest = await RegistrationRequest.findOne({ registrationId });
    if (!regRequest) {
      return res.status(404).json({
        success: false,
        message: "Registration session not found.",
      });
    }

    const rawOtp = String(Math.floor(100000 + Math.random() * 900000));
    const otpHash = hashOtp(rawOtp);
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

    await Otp.deleteMany({ phoneNumber: regRequest.phoneNumber });
    await Otp.create({
      phoneNumber: regRequest.phoneNumber,
      otpHash,
      attempts: 0,
      expiresAt,
    });

    const smsResult = await sendOtp(regRequest.phoneNumber, rawOtp);

    return res.status(200).json({
      success: true,
      message: "A new OTP has been sent to your mobile number.",
      smsGatewayStatus: smsResult.provider,
    });
  } catch (error) {
    console.error("Resend OTP error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to resend OTP. Please try again.",
    });
  }
};

/**
 * 4. Create Password & Finalize Pending Registration
 */
const createPassword = async (req, res) => {
  try {
    const { registrationId, password, confirmPassword } = req.body;

    if (!registrationId || !password || !confirmPassword) {
      return res.status(400).json({
        success: false,
        message: "Registration ID, Password, and Confirm Password are required.",
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

    const regRequest = await RegistrationRequest.findOne({ registrationId });
    if (!regRequest) {
      return res.status(404).json({
        success: false,
        message: "Registration record not found.",
      });
    }

    if (!regRequest.mobileVerified) {
      return res.status(400).json({
        success: false,
        message: "Mobile number has not been verified yet.",
      });
    }

    // Hash Password securely with bcrypt (12 salt rounds)
    const salt = await bcrypt.genSalt(12);
    const passwordHash = await bcrypt.hash(password, salt);

    // Assign candidate member ID (e.g. SHG-011)
    const totalUsers = await User.countDocuments();
    const assignedMemberId = `SHG-${String(totalUsers + 1).padStart(3, "0")}`;

    regRequest.passwordHash = passwordHash;
    regRequest.assignedMemberId = assignedMemberId;
    regRequest.status = "pending_approval";
    await regRequest.save();

    return res.status(200).json({
      success: true,
      registrationId: regRequest.registrationId,
      assignedMemberId,
      groupId: regRequest.groupId,
      status: "pending_approval",
      message: "Mobile number verified! Your membership request has been submitted to group " + regRequest.groupId + " and is awaiting approval from your group President or Secretary.",
    });
  } catch (error) {
    console.error("Create password error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to create password.",
    });
  }
};

/**
 * 5. Check Membership Request Status by Phone Number
 */
const checkRegistrationStatus = async (req, res) => {
  try {
    const { phoneNumber } = req.params;
    const cleanPhone = String(phoneNumber).trim().replace(/\D/g, "");

    const regRequest = await RegistrationRequest.findOne({ phoneNumber: cleanPhone }).sort({ createdAt: -1 });
    if (!regRequest) {
      return res.status(404).json({
        success: false,
        message: "No registration request found for this mobile number.",
      });
    }

    return res.status(200).json({
      success: true,
      registrationId: regRequest.registrationId,
      fullName: regRequest.fullName,
      phoneNumber: regRequest.phoneNumber,
      groupId: regRequest.groupId,
      requestedRole: regRequest.requestedRole,
      status: regRequest.status,
      assignedMemberId: regRequest.assignedMemberId,
      rejectionReason: regRequest.rejectionReason,
    });
  } catch (error) {
    console.error("Check registration status error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch registration status.",
    });
  }
};

module.exports = {
  initiateRegistration,
  verifyOtp,
  resendOtp,
  createPassword,
  checkRegistrationStatus,
};
