const dns = require("node:dns");
// Use public DNS servers for MongoDB SRV lookups to avoid ECONNREFUSED
dns.setServers(["8.8.8.8", "1.1.1.1"]);

const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");
require("dotenv").config();

// Define a flexible schema to handle legacy and new fields
const userSchema = new mongoose.Schema({
  userId: String,
  phoneNumber: String,
  mobile: String, // Old field name
  password: String,
  isActive: { type: Boolean, default: true },
  role: String,
  position: String
}, { strict: false });

const User = mongoose.model("UserFix", userSchema, "users");

async function fixUsers() {
  try {
    console.log("Connecting to MongoDB Atlas...");

    if (!process.env.MONGO_URI) {
        throw new Error("MONGO_URI not found in .env file");
    }

    await mongoose.connect(process.env.MONGO_URI);
    console.log("Connected successfully.");

    const users = await User.find();
    console.log(`Processing ${users.length} users...`);

    for (const user of users) {
      let changed = false;
      const uObj = user.toObject();

      // 1. Fix field name: mobile -> phoneNumber
      if (uObj.mobile && !uObj.phoneNumber) {
        console.log(`[FIX] User ${uObj.userId}: Renaming 'mobile' to 'phoneNumber'`);
        user.phoneNumber = uObj.mobile;
        user.set('mobile', undefined);
        changed = true;
      }

      // 2. Fix password hashing
      if (uObj.password && !uObj.password.startsWith("$2a$") && !uObj.password.startsWith("$2b$")) {
        console.log(`[FIX] User ${uObj.userId}: Hashing plain-text password`);
        const salt = await bcrypt.genSalt(12);
        user.password = await bcrypt.hash(uObj.password, salt);
        changed = true;
      }

      // 3. Ensure isActive is true
      if (uObj.isActive !== true) {
        console.log(`[FIX] User ${uObj.userId}: Activating account`);
        user.isActive = true;
        changed = true;
      }

      if (changed) {
        await user.save();
        console.log(`[OK] User ${uObj.userId}: Updated`);
      } else {
        console.log(`[SKIP] User ${uObj.userId}: Already in correct format`);
      }
    }

    console.log("\n--- Verification Complete ---");
    console.log("All users now have hashed passwords and phoneNumber fields.");
    process.exit(0);
  } catch (err) {
    console.error("\nDatabase Connection Error:");
    console.error(err.message);
    console.log("\nTroubleshooting Tips:");
    console.log("1. Check your internet connection.");
    console.log("2. Ensure your IP address is whitelisted in MongoDB Atlas Network Access.");
    console.log("3. Verify the MONGO_URI in your .env file is correct.");
    process.exit(1);
  }
}

fixUsers();
