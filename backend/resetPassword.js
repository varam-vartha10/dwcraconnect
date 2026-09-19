const dns = require("node:dns");
dns.setServers(["8.8.8.8", "1.1.1.1"]);

const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");
require("dotenv").config();

const User = require("./src/models/User");

async function reset() {
  try {
    console.log("Connecting to MongoDB Atlas...");
    await mongoose.connect(process.env.MONGO_URI, { dbName: "dwcra_connect" });
    console.log("Connected.");

    const userId = "SHG-001";
    const newPassword = "123456";

    const user = await User.findOne({ userId });

    if (!user) {
      console.log(`User ${userId} NOT FOUND.`);
      process.exit(1);
    }

    console.log(`Found user: ${user.name}`);

    // Using Sync methods to be 100% sure with bcryptjs
    const salt = bcrypt.genSaltSync(12);
    const hash = bcrypt.hashSync(newPassword, salt);

    user.password = hash;
    await user.save();

    console.log(`Password for ${userId} has been reset to '123456' (hashed).`);

    // Verify it immediately
    const matches = bcrypt.compareSync(newPassword, user.password);
    console.log(`Verification check: ${matches ? "PASS" : "FAIL"}`);

    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

reset();
