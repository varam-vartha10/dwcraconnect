const dns = require("node:dns");
dns.setServers(["8.8.8.8", "1.1.1.1"]);

const mongoose = require("mongoose");
require("dotenv").config();

const User = require("./src/models/User");

async function diagnostic() {
  try {
    console.log("Connecting to MongoDB Atlas...");
    await mongoose.connect(process.env.MONGO_URI);
    console.log("Connected.");

    const groupId = "GRP001";
    const users = await User.find({ groupId }).sort({ userId: 1 });

    console.log(`Group: ${groupId}`);
    console.log(`Users found: ${users.length}`);

    users.forEach((u, index) => {
      console.log(`${index + 1}. UserID: ${u.userId} | Phone: ${u.phoneNumber} | Role: ${u.role} | Position: ${u.position} | Active: ${u.isActive}`);
    });

    if (users.length === 10) {
      console.log("SUCCESS: Exactly 10 users found in GRP001.");
    } else {
      console.log(`WARNING: Expected 10 users, but found ${users.length}.`);
    }

    process.exit(0);
  } catch (err) {
    console.error("Diagnostic failed:", err.message);
    process.exit(1);
  }
}

diagnostic();
