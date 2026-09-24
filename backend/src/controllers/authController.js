const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const mongoose = require("mongoose");
const User = require("../models/User");

const login = async (req, res) => {
  try {
    let { phoneNumber, password } = req.body;

    // 1. Diagnostics (Safe logs for development)
    if (process.env.NODE_ENV !== "production") {
      console.log(`[Auth] MongoDB readyState: ${mongoose.connection.readyState}`);
      console.log(`[Auth] Login attempt for phone: ${phoneNumber}`);
    }

    if (!phoneNumber || !password) {
      return res.status(400).json({
        success: false,
        message: "Phone number and password are required",
      });
    }

    phoneNumber = String(phoneNumber).trim();

    // 2. Find user (First check indexed phoneNumber, fallback to legacy mobile field)
    let user = await User.findOne({ phoneNumber: phoneNumber, isActive: true });
    if (!user) {
      user = await User.findOne({ mobile: phoneNumber, isActive: true });
    }

    if (!user) {
      if (process.env.NODE_ENV !== "production") {
        console.log(`[Auth] Login failed: User not found or inactive (${phoneNumber})`);
      }
      return res.status(401).json({
        success: false,
        message: "Invalid phone number or password",
      });
    }

    // 3. Verify password
    // Support both hashed and legacy plain-text (only if absolutely necessary for transition)
    // Here we strictly check bcrypt
    const isHashed = user.password.startsWith("$2a$") || user.password.startsWith("$2b$");

    if (!isHashed) {
      // If it's not hashed, it's a legacy plain-text password
      if (process.env.NODE_ENV !== "production") {
        console.log(`[Auth] CRITICAL: Plain-text password detected for user ${user.userId}.`);
      }
      if (password !== user.password) {
        return res.status(401).json({
          success: false,
          message: "Invalid phone number or password",
        });
      }
    } else {
      const passwordMatches = await bcrypt.compare(password, user.password);
      if (!passwordMatches) {
        if (process.env.NODE_ENV !== "production") {
          console.log(`[Auth] Login failed: Password mismatch for ${user.userId}`);
        }
        return res.status(401).json({
          success: false,
          message: "Invalid phone number or password",
        });
      }
    }

    // 4. Successful login
    if (process.env.NODE_ENV !== "production") {
      console.log(`[Auth] Login successful: ${user.userId}`);
    }

    if (!process.env.JWT_SECRET) {
      console.error("CRITICAL: JWT_SECRET environment variable is not set.");
      return res.status(500).json({
        success: false,
        message: "Internal server error. Authentication service is misconfigured.",
      });
    }

    const token = jwt.sign(
      { id: user._id, userId: user.userId, role: user.role, groupId: user.groupId },
      process.env.JWT_SECRET,
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

const changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    const user = await User.findById(req.user.id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    const isMatch = await bcrypt.compare(currentPassword, user.password);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: "Current password is incorrect",
      });
    }

    const salt = await bcrypt.genSalt(12);
    user.password = await bcrypt.hash(newPassword, salt);
    await user.save();

    res.status(200).json({
      success: true,
      message: "Password changed successfully",
    });
  } catch (error) {
    console.error("Change password error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to change password",
    });
  }
};

module.exports = {
  login,
  getMe,
  changePassword,
};
