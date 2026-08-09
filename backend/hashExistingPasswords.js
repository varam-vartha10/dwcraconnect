const bcrypt = require("bcryptjs");
require("dotenv").config();

const connectDatabase = require("./src/config/database");
const User = require("./src/models/User");

async function migratePasswords() {
  try {
    // Use the same MongoDB connection as the main backend
    await connectDatabase();

    const users = await User.find();

    console.log(`Found ${users.length} users.`);

    let updated = 0;
    let skipped = 0;

    for (const user of users) {
      // Skip passwords that are already bcrypt hashes
      if (
        typeof user.password === "string" &&
        user.password.startsWith("$2")
      ) {
        console.log(`${user.userId}: already hashed`);
        skipped++;
        continue;
      }

      const hashedPassword = await bcrypt.hash(user.password, 12);

      user.password = hashedPassword;

      await user.save();

      console.log(`${user.userId}: password hashed`);
      updated++;
    }

    console.log("--------------------------------");
    console.log(`Updated: ${updated}`);
    console.log(`Skipped: ${skipped}`);
    console.log("--------------------------------");
    console.log("Password migration completed successfully.");

    process.exit(0);
  } catch (error) {
    console.error("Password migration failed:", error);
    process.exit(1);
  }
}

migratePasswords();