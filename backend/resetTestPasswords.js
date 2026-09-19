const dns = require("node:dns");
dns.setServers(["8.8.8.8", "1.1.1.1"]);

const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");
require("dotenv").config();

const User = require("./src/models/User");

async function resetAll() {
  // EXPLICITLY TRIM to avoid CMD/PowerShell space accidents
  let testPassword = process.env.TEST_PASSWORD;

  if (testPassword) {
      testPassword = testPassword.trim();
  } else {
      testPassword = "123456";
  }

  console.log(`Resetting all 10 users to password: '${testPassword}'`);

  try {
    console.log("Connecting to MongoDB Atlas...");
    await mongoose.connect(process.env.MONGO_URI);
    console.log("Connected.");

    const groupId = "GRP001";
    const users = await User.find({ groupId });

    if (users.length !== 10) {
      console.error(`ERROR: Expected 10 users, found ${users.length}.`);
      process.exit(1);
    }

    let updatedCount = 0;
    let verifiedCount = 0;

    for (const user of users) {
      const hash = await bcrypt.hash(testPassword, 12);

      // Use updateOne with $set to bypass any potential hooks and be direct
      await User.updateOne(
        { userId: user.userId },
        { $set: { password: hash } }
      );

      updatedCount++;

      // Verify immediately
      const updatedUser = await User.findOne({ userId: user.userId });
      const isCorrect = await bcrypt.compare(testPassword, updatedUser.password);
      if (isCorrect) {
        verifiedCount++;
        console.log(`${user.userId}: PASS`);
      } else {
        console.log(`${user.userId}: FAIL (Verification failed after update)`);
      }
    }

    console.log("\n--- Summary ---");
    console.log(`Updated users: ${updatedCount}/10`);
    console.log(`Verified users: ${verifiedCount}/10`);

    if (verifiedCount === 10) {
      console.log("SUCCESS: All passwords reset and verified successfully.");
      process.exit(0);
    } else {
      process.exit(1);
    }
  } catch (err) {
    console.error("Reset failed:", err.message);
    process.exit(1);
  }
}

resetAll();
