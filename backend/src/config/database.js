const mongoose = require("mongoose");

const connectDatabase = async () => {
  try {
    console.log("Connecting to MongoDB Atlas connection pool...");

    await mongoose.connect(process.env.MONGO_URI, {
      serverSelectionTimeoutMS: 10000,
      dbName: "dwcra_connect",
      maxPoolSize: 10,
      minPoolSize: 2,
      socketTimeoutMS: 45000,
    });

    console.log("MongoDB connected successfully with pre-warmed connection pool.");

    // Ensure compound indexes exist for instant authentication and financial lookups
    const User = require("../models/User");
    const Loan = require("../models/Loan");
    const Emi = require("../models/Emi");
    const Transaction = require("../models/Transaction");

    await User.collection.createIndex({ phoneNumber: 1, isActive: 1 }).catch(() => {});
    await Loan.collection.createIndex({ memberId: 1, groupId: 1 }).catch(() => {});
    await Emi.collection.createIndex({ memberId: 1, status: 1 }).catch(() => {});
    await Transaction.collection.createIndex({ memberId: 1, createdAt: -1 }).catch(() => {});

  } catch (error) {
    console.error("MongoDB connection failed:");
    console.error(error);
    throw error;
  }
};

module.exports = connectDatabase;
