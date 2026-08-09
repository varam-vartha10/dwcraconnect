const User = require("../models/User");
const bcrypt = require("bcryptjs");

// Get all users
const getUsers = async (req, res) => {
  try {
    const users = await User.find().select("-password");

    res.status(200).json({
      success: true,
      count: users.length,
      users,
    });
  } catch (error) {
    console.error("Get users error:", error);

    res.status(500).json({
      success: false,
      message: "Failed to fetch users",
    });
  }
};

// Get users by group
const getUsersByGroup = async (req, res) => {
  try {
    const { groupId } = req.params;

    const users = await User.find({ groupId }).select("-password");

    res.status(200).json({
      success: true,
      count: users.length,
      users,
    });
  } catch (error) {
    console.error("Get group users error:", error);

    res.status(500).json({
      success: false,
      message: "Failed to fetch group members",
    });
  }
};

// Create user
const createUser = async (req, res) => {
  try {
    const {
      userId,
      groupId,
      name,
      phoneNumber,
      password,
      role,
      position,
      aadhaar,
      village,
    } = req.body;

    if (
      !userId ||
      !groupId ||
      !name ||
      !phoneNumber ||
      !password ||
      !role ||
      !position
    ) {
      return res.status(400).json({
        success: false,
        message: "Required fields are missing",
      });
    }

    const existingUser = await User.findOne({
      $or: [{ userId }, { phoneNumber }],
    });

    if (existingUser) {
      return res.status(409).json({
        success: false,
        message: "User ID or phone number already exists",
      });
    }
    const hashedPassword = await bcrypt.hash(password, 12);
    const user = await User.create({
    userId,
    groupId,
    name,
    phoneNumber,
    password: hashedPassword,
    role,
    position,
    aadhaar,
    village,
    });

    const safeUser = user.toObject();
    delete safeUser.password;

    res.status(201).json({
      success: true,
      message: "User created successfully",
      user: safeUser,
    });
  } catch (error) {
    console.error("Create user error:", error);

    res.status(500).json({
      success: false,
      message: "Failed to create user",
    });
  }
};




const migratePasswords = async (req, res) => {
  try {
    const users = await User.find();

    let updated = 0;
    let skipped = 0;

    for (const user of users) {
      if (
        typeof user.password === "string" &&
        user.password.startsWith("$2")
      ) {
        console.log(`${user.userId}: already hashed`);
        skipped++;
        continue;
      }

      user.password = await bcrypt.hash(user.password, 12);

      await user.save();

      console.log(`${user.userId}: password hashed`);
      updated++;
    }

    res.status(200).json({
      success: true,
      message: "Password migration completed",
      totalUsers: users.length,
      updated,
      skipped,
    });
  } catch (error) {
    console.error("Password migration error:", error);

    res.status(500).json({
      success: false,
      message: "Password migration failed",
    });
  }
};

module.exports = {
  getUsers,
  getUsersByGroup,
  createUser,
  migratePasswords,
};