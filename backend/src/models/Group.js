const mongoose = require("mongoose");

const groupSchema = new mongoose.Schema(
  {
    groupId: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },

    groupName: {
      type: String,
      required: true,
      trim: true,
    },

    village: {
      type: String,
      trim: true,
    },

    mandal: {
      type: String,
      trim: true,
    },

    district: {
      type: String,
      trim: true,
    },

    state: {
      type: String,
      default: "Andhra Pradesh",
    },

    presidentId: {
      type: String,
      default: null,
    },

    secretaryId: {
      type: String,
      default: null,
    },

    maxMembers: {
      type: Number,
      default: 10,
    },

    status: {
      type: String,
      enum: ["active", "inactive"],
      default: "active",
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("Group", groupSchema);