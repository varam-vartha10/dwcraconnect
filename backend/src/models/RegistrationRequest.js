const mongoose = require("mongoose");

const registrationRequestSchema = new mongoose.Schema(
  {
    registrationId: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },
    fullName: {
      type: String,
      required: true,
      trim: true,
    },
    phoneNumber: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      index: true,
    },
    altPhoneNumber: {
      type: String,
      default: null,
    },
    dob: {
      type: String,
      default: null,
    },
    village: {
      type: String,
      required: true,
      trim: true,
    },
    mandal: {
      type: String,
      required: true,
      trim: true,
    },
    district: {
      type: String,
      required: true,
      trim: true,
    },
    state: {
      type: String,
      default: "Andhra Pradesh",
    },
    preferredLanguage: {
      type: String,
      enum: ["en", "te"],
      default: "en",
    },
    groupId: {
      type: String,
      required: true,
      index: true,
    },
    requestedRole: {
      type: String,
      enum: ["president", "secretary", "member"],
      default: "member",
    },

    // Optional self-reported initial financial information (UNVERIFIED)
    initialFinancials: {
      hasLoan: { type: Boolean, default: false },
      provider: { type: String, default: null },
      accountNumber: { type: String, default: null },
      originalAmount: { type: Number, default: null },
      outstandingBalance: { type: Number, default: null },
      emiAmount: { type: Number, default: null },
      emiFrequency: { type: String, default: "monthly" },
      nextEmiDueDate: { type: String, default: null },
      totalInstallments: { type: Number, default: null },
      paidInstallments: { type: Number, default: null },
      loanStartDate: { type: String, default: null },
      hasSubsidy: { type: Boolean, default: false },
      subsidyAmount: { type: Number, default: null },
      isVerified: { type: Boolean, default: false },
    },

    passwordHash: {
      type: String,
      default: null,
    },
    mobileVerified: {
      type: Boolean,
      default: false,
    },
    status: {
      type: String,
      enum: ["pending_otp", "pending_password", "pending_approval", "approved", "rejected"],
      default: "pending_otp",
    },
    rejectionReason: {
      type: String,
      default: null,
    },
    approvedBy: {
      type: String,
      default: null,
    },
    assignedMemberId: {
      type: String,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("RegistrationRequest", registrationRequestSchema);
