const dns = require("node:dns");
dns.setServers(["8.8.8.8", "1.1.1.1"]);

const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");
require("dotenv").config();

const User = require("./src/models/User");

async function debug() {
  const testPassword = process.env.TEST_PASSWORD || "123456";
  console.log(`Starting debug with test password: '${testPassword}'`);

  try {
    console.log("Connecting to MongoDB Atlas...");
    await mongoose.connect(process.env.MONGO_URI);
    console.log("Connected.");

    const groupId = "GRP001";
    const users = await User.find({ groupId }).sort({ userId: 1 });

    console.log(`Found ${users.length} users in GRP001`);

    for (const user of users) {
      const storedHash = user.password;
      const isCorrect = bcrypt.compareSync(testPassword, storedHash);

      // Safe check: does the hash look like a bcrypt hash?
      const looksLikeHash = storedHash && (storedHash.startsWith("$2a$") || storedHash.startsWith("$2b$") || storedHash.startsWith("$2y$"));
      const hashLength = storedHash ? storedHash.length : 0;

      console.log(`${user.userId}:
        Phone: ${user.phoneNumber}
        Active: ${user.isActive}
        Hash length: ${hashLength}
        Looks like hash: ${looksLikeHash}
        Bcrypt check: ${isCorrect ? "PASS" : "FAIL"}
      `);

      if (!isCorrect && looksLikeHash) {
          // If it fails but looks like a hash, maybe it was double hashed?
          // Let's try to see if the hash ITSELF is what we are comparing against.
          // NO, that's unlikely.

          // Let's try to hash the test password and see if it matches if we compare again?
          // No, that's what compareSync does.
      }
    }

    process.exit(0);
  } catch (err) {
    console.error("Debug failed:", err.message);
    process.exit(1);
  }
}

debug();
