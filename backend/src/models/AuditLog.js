const mongoose = require("mongoose");

const auditLogSchema = new mongoose.Schema(
  {
    memberId: {
      type: String,
      required: true,
      index: true,
    },
    groupId: {
      type: String,
      required: true,
      index: true,
    },
    actingLeaderId: {
      type: String,
      required: true,
    },
    action: {
      type: String,
      required: true,
    },
    phoneNumberMasked: {
      type: String,
      default: null,
    },
    details: {
      type: String,
      default: "",
    },
    physicalRegisterChecked: {
      type: Boolean,
      default: false,
    },
    timestamp: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("AuditLog", auditLogSchema);
