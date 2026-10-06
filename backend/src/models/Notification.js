const mongoose = require("mongoose");

const notificationSchema = new mongoose.Schema(
  {
    notificationId: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      index: true,
    },

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

    title: {
      type: String,
      required: true,
      trim: true,
    },

    message: {
      type: String,
      required: true,
      trim: true,
    },

    type: {
      type: String,
      enum: [
        "emi_upcoming",
        "emi_due",
        "emi_overdue",
        "payment_success",
        "emi_reminder",
        "payment_confirmation",
        "loan_update",
        "subsidy_update",
        "group_notification",
        "general",
        "other"
      ],
      default: "general",
      index: true,
    },

    stage: {
      type: String,
      default: null, // "7_days", "3_days", "1_day", "due_today", "overdue", "payment_success"
    },

    isRead: {
      type: Boolean,
      default: false,
      index: true,
    },

    relatedId: {
      type: String,
      default: null, // loanId, emiId, or transactionId
    },
  },
  {
    timestamps: true,
  }
);

// Compound index for fast lookup of member notifications
notificationSchema.index({ memberId: 1, createdAt: -1 });

module.exports = mongoose.model("Notification", notificationSchema);
