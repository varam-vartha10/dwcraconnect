const mongoose = require("mongoose");

const emiSchema = new mongoose.Schema(
  {
    emiId: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      index: true,
    },

    loanId: {
      type: String,
      required: true,
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

    installmentNumber: {
      type: Number,
      required: true,
      min: 1,
    },

    amount: {
      type: Number,
      required: true,
      min: 0,
    },

    dueDate: {
      type: Date,
      required: true,
      index: true,
    },

    status: {
      type: String,
      enum: ["pending", "paid", "overdue", "waived"],
      default: "pending",
      index: true,
    },

    paidDate: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

emiSchema.index(
  { loanId: 1, installmentNumber: 1 },
  { unique: true }
);

module.exports = mongoose.model("Emi", emiSchema);