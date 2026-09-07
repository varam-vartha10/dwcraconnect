const mongoose = require("mongoose");
require("dotenv").config();

const User = require("./src/models/User");

async function checkUsers() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log("Connected to MongoDB");

    const users = await User.find();
    console.log(`Found ${users.length} users in total.`);

    users.forEach(u => {
      const isHashed = u.password.startsWith("$2a$") || u.password.startsWith("$2b$");
      console.log(`User: ${u.userId} | Phone: ${u.phoneNumber} | Active: ${u.isActive} | HashDetected: ${isHashed} | Role: ${u.role}`);
    });

    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

checkUsers();
