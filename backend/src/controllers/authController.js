const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const User = require("../models/User");

const login = async (req, res) => {
  try {
    const { phoneNumber, password } = req.body;

    if (!phoneNumber || !password) {
      return res.status(400).json({
        success: false,
        message: "Phone number and password are required",
      });
    }

    // Normalize input
    const normalizedPhone = String(phoneNumber).trim();

    // Debug DB connection
    const dbName = User.db.name;
    console.log(`[Auth] Login attempt for: ${normalizedPhone} on DB: ${dbName}`);

    // 1. Find the active user (Check both phoneNumber and legacy mobile field)
    const user = await User.findOne({
      $or: [
        { phoneNumber: normalizedPhone },
        { mobile: normalizedPhone }
      ],
      isActive: true,
    });

    if (!user) {
      console.log(`[Auth] User not found: ${normalizedPhone}`);
      return res.status(401).json({
        success: false,
        message: "Invalid phone number or password",
      });
    }

    // 2. Verify password using bcryptjs
    const isPasswordCorrect = await bcrypt.compare(password, user.password);

    if (!isPasswordCorrect) {
      console.log(`[Auth] Password mismatch for: ${user.userId}`);
      return res.status(401).json({
        success: false,
        message: "Invalid phone number or password",
      });
    }

    // 3. Check for JWT_SECRET
    if (!process.env.JWT_SECRET) {
      console.error("CRITICAL: JWT_SECRET missing");
      return res.status(500).json({
        success: false,
        message: "Authentication service misconfigured",
      });
    }

    // 4. Generate JWT
    const token = jwt.sign(
      {
        id: user._id,
        userId: user.userId,
        role: user.role,
        groupId: user.groupId
      },
      process.env.JWT_SECRET,
      { expiresIn: "30d" }
    );

    // 5. Send successful response
    const safeUser = user.toObject();
    delete safeUser.password;

    return res.status(200).json({
      success: true,
      message: "Login successful",
      token,
      user: safeUser,
    });
  } catch (error) {
    console.error("Login Error:", error.message);
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
