const User = require("../models/User");
const Group = require("../models/Group");
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
    let {
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

    // 1. Validation
    if (!userId || !groupId || !name || !phoneNumber || !password || !role || !position) {
      return res.status(400).json({
        success: false,
        message: "Required fields are missing",
      });
    }

    // 2. Normalize and check combination
    userId = userId.trim();
    phoneNumber = String(phoneNumber).trim();

    if (role === "member" && position !== "member") {
      return res.status(400).json({
        success: false,
        message: "Invalid position for 'member' role. Must be 'member'.",
      });
    }

    if (role === "leader" && !["president", "secretary"].includes(position)) {
      return res.status(400).json({
        success: false,
        message: "Invalid position for 'leader' role. Must be 'president' or 'secretary'.",
      });
    }

    // 3. Check for duplicates (Checking both phoneNumber and legacy mobile field)
    const existingUser = await User.findOne({
      $or: [
        { userId: userId },
        { phoneNumber: phoneNumber },
        { mobile: phoneNumber }
      ],
    });

    if (existingUser) {
      return res.status(409).json({
        success: false,
        message: "User ID or phone number already exists",
      });
    }

    // 4. Group business rule: max 10 members
    const groupMemberCount = await User.countDocuments({ groupId, isActive: true });
    if (groupMemberCount >= 10) {
      return res.status(400).json({
        success: false,
        message: "Group already has the maximum of 10 members",
      });
    }

    // 5. Hash password
    const salt = await bcrypt.genSalt(12);
    const hashedPassword = await bcrypt.hash(password, salt);

    // 6. Create user
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
      isActive: true
    });

    const safeUser = user.toObject();
    delete safeUser.password;

    console.log(`[User] New user created: ${user.userId}`);

    res.status(201).json({
      success: true,
      message: "User created successfully",
      user: safeUser,
    });
  } catch (error) {
    console.error("[User] Create user error:", error);
    res.status(500).json({
      success: false,
      message: "An internal server error occurred while creating user",
    });
  }
};

const migratePasswords = async (req, res) => {
  try {
    const users = await User.find();
    let updated = 0;
    let skipped = 0;

    for (const user of users) {
      if (typeof user.password === "string" && (user.password.startsWith("$2a$") || user.password.startsWith("$2b$"))) {
        skipped++;
        continue;
      }

      const salt = await bcrypt.genSalt(12);
      user.password = await bcrypt.hash(user.password, salt);
      await user.save();
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
