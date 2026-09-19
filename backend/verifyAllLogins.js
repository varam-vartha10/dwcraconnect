const dns = require("node:dns");
dns.setServers(["8.8.8.8", "1.1.1.1"]);

const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");
require("dotenv").config();

const User = require("./src/models/User");

async function verifyAll() {
  let testPassword = process.env.TEST_PASSWORD;

  if (testPassword) {
      testPassword = testPassword.trim();
  } else {
      testPassword = "123456";
  }

  console.log(`Verifying logins using password: '${testPassword}'`);

  try {
    console.log("Connecting to MongoDB Atlas...");
    await mongoose.connect(process.env.MONGO_URI, { dbName: "dwcra_connect" });
    console.log("Connected.");

    const groupId = "GRP001";
    const users = await User.find({ groupId }).sort({ userId: 1 });

    if (users.length !== 10) {
      console.error(`ERROR: Expected 10 users, found ${users.length}.`);
      process.exit(1);
    }

    let passedCount = 0;
    for (const user of users) {
      const isCorrect = await bcrypt.compare(testPassword, user.password);

      if (isCorrect && user.isActive) {
        console.log(`${user.userId}: PASS`);
        passedCount++;
      } else {
        console.log(`${user.userId}: FAIL`);
        if (!isCorrect) console.log("  - Password mismatch");
        if (!user.isActive) console.log("  - User inactive");
      }
    }

    console.log(`\nResult: ${passedCount}/10 PASSED`);

    if (passedCount === 10) {
        console.log("SUCCESS: All users passed verification.");
        process.exit(0);
    } else {
        console.error("FAILURE: Not all users passed.");
        process.exit(1);
    }
  } catch (err) {
    console.error("Verification failed:", err.message);
    process.exit(1);
  }
}

verifyAll();
