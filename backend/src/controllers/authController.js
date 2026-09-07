const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const User = require("../models/User");

const login = async (req, res) => {
  try {
    let { phoneNumber, password } = req.body;

    console.log(`[Auth] Login attempt for phone: ${phoneNumber}`);

    if (!phoneNumber || !password) {
      return res.status(400).json({
        success: false,
        message: "Phone number and password are required",
      });
    }

    phoneNumber = String(phoneNumber).trim();

    const user = await User.findOne({
      $or: [
        { phoneNumber: phoneNumber },
        { mobile: phoneNumber }
      ],
      isActive: true,
    });

    if (!user) {
      console.log(`[Auth] Login failed: User not found or inactive (${phoneNumber})`);
      return res.status(401).json({
        success: false,
        message: "Invalid phone number or password",
      });
    }

    const isHashed = user.password.startsWith("$2a$") || user.password.startsWith("$2b$");

    if (!isHashed) {
      console.log(`[Auth] CRITICAL: Plain-text password detected for user ${user.userId}.`);
      if (password !== user.password) {
        return res.status(401).json({
          success: false,
          message: "Invalid phone number or password",
        });
      }
    } else {
      const passwordMatches = await bcrypt.compare(password, user.password);
      if (!passwordMatches) {
        console.log(`[Auth] Login failed: Password mismatch for ${user.userId}`);
        return res.status(401).json({
          success: false,
          message: "Invalid phone number or password",
        });
      }
    }

    console.log(`[Auth] Login successful: ${user.userId}`);

    const token = jwt.sign(
      { id: user._id, userId: user.userId, role: user.role, groupId: user.groupId },
      process.env.JWT_SECRET || "fallback_secret",
      { expiresIn: "30d" }
    );

    const safeUser = user.toObject();
    delete safeUser.password;

    return res.status(200).json({
      success: true,
      message: "Login successful",
      token,
      user: safeUser,
    });
  } catch (error) {
    console.error("[Auth] Login error:", error);
    return res.status(500).json({
      success: false,
      message: "An internal server error occurred",
    });
  }
};

const getMe = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select("-password");
    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    res.status(200).json({
      success: true,
      user,
    });
  } catch (error) {
    console.error("[Auth] GetMe error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch user profile",
    });
  }
};

module.exports = {
  login,
  getMe,
};
