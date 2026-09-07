const mongoose = require("mongoose");

const notificationSchema = new mongoose.Schema(
  {
    notificationId: {
      type: String,
      required: true,
      unique: true,
      trim: true,
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
        "emi_reminder",
        "payment_confirmation",
        "loan_update",
        "subsidy_update",
        "group_notification",
        "other"
      ],
      default: "other",
    },

    isRead: {
      type: Boolean,
      default: false,
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

module.exports = mongoose.model("Notification", notificationSchema);
