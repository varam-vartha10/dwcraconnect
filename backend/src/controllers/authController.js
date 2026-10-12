const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const mongoose = require("mongoose");
const User = require("../models/User");

const login = async (req, res) => {
  const startTime = Date.now();
  try {
    let { phoneNumber, password } = req.body;

    if (!phoneNumber || !password) {
      return res.status(400).json({
        success: false,
        message: "Phone number and password are required",
      });
    }

    phoneNumber = String(phoneNumber).trim();

    // 1. Fast indexed lookup with .lean() to skip document hydration
    let user = await User.findOne({ phoneNumber: phoneNumber, isActive: true }).lean();
    if (!user) {
      user = await User.findOne({ mobile: phoneNumber, isActive: true }).lean();
    }

    if (!user) {
      return res.status(401).json({
        success: false,
        message: "Invalid phone number or password",
      });
    }

    // 2. Verify password
    const isHashed = user.password.startsWith("$2a$") || user.password.startsWith("$2b$");

    if (!isHashed) {
      if (password !== user.password) {
        return res.status(401).json({
          success: false,
          message: "Invalid phone number or password",
        });
      }
    } else {
      const passwordMatches = await bcrypt.compare(password, user.password);
      if (!passwordMatches) {
        return res.status(401).json({
          success: false,
          message: "Invalid phone number or password",
        });
      }
    }

    // 3. Issue JWT Token
    if (!process.env.JWT_SECRET) {
      console.error("CRITICAL: JWT_SECRET environment variable is not set.");
      return res.status(500).json({
        success: false,
        message: "Internal server error. Authentication service is misconfigured.",
      });
    }

    const token = jwt.sign(
      { id: user._id.toString(), userId: user.userId, role: user.role, groupId: user.groupId, position: user.position },
      process.env.JWT_SECRET,
      { expiresIn: "30d" }
    );

    const safeUser = { ...user };
    delete safeUser.password;
    delete safeUser.__v;

    if (process.env.NODE_ENV !== "production") {
      console.log(`[Auth] Login successful for ${user.userId} in ${Date.now() - startTime}ms`);
    }

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
    const user = await User.findById(req.user.id).select("-password").lean();
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
