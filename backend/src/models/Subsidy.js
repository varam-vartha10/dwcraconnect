const mongoose = require("mongoose");

const subsidySchema = new mongoose.Schema(
  {
    subsidyId: {
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

    schemeName: {
      type: String,
      required: true,
      trim: true,
    },

    amount: {
      type: Number,
      required: true,
      min: 0,
    },

    status: {
      type: String,
      enum: ["pending", "received", "disbursed"],
      default: "pending",
      index: true,
    },

    dateReceived: {
      type: Date,
      default: null,
    },

    description: {
      type: String,
      trim: true,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("Subsidy", subsidySchema);