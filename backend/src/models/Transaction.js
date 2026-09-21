const mongoose = require("mongoose");

const transactionSchema = new mongoose.Schema(
  {
    transactionId: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      index: true,
    },

    loanId: {
      type: String,
      default: null,
      index: true,
    },

    emiId: {
      type: String,
      default: null,
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

    amount: {
      type: Number,
      required: true,
      min: 0,
    },

    type: {
      type: String,
      enum: [
        "loan_payment",
        "savings_deposit",
        "savings_withdrawal",
        "subsidy",
        "other"
      ],
      required: true,
      index: true,
    },

    status: {
      type: String,
      enum: ["pending", "completed", "failed", "cancelled"],
      default: "pending",
      index: true,
    },

    paymentDate: {
      type: Date,
      default: Date.now,
      index: true,
    },

    notes: {
      type: String,
      default: "",
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("Transaction", transactionSchema);