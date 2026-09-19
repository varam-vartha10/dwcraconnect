const dns = require("node:dns");
dns.setServers(["8.8.8.8", "1.1.1.1"]);

const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");
require("dotenv").config();

const User = require("./src/models/User");

async function verify() {
  try {
    console.log("Connecting to MongoDB Atlas...");
    await mongoose.connect(process.env.MONGO_URI);
    console.log("Connected.");

    const phone = "9000000001";
    const testPassword = "123456";

    const user = await User.findOne({
      $or: [{ phoneNumber: phone }, { mobile: phone }]
    });

    if (!user) {
      console.log(`User with phone ${phone} NOT FOUND.`);
      process.exit(1);
    }

    console.log("--- User Found ---");
    console.log(`User ID: ${user.userId}`);
    console.log(`Phone: ${user.phoneNumber}`);
    console.log(`Is Active: ${user.isActive}`);

    const hash = user.password;
    const isHashed = hash.startsWith("$2a$") || hash.startsWith("$2b$");
    console.log(`Password is hashed: ${isHashed}`);

    if (isHashed) {
        const matches = await bcrypt.compare(testPassword, hash);
        console.log(`Does '123456' match the stored hash? ${matches}`);
    } else {
        console.log(`Stored password is plain text: ${hash === testPassword ? "MATCHES 123456" : "DOES NOT MATCH"}`);
    }

    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

verify();
