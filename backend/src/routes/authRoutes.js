const express = require("express");
const { login, getMe, changePassword } = require("../controllers/authController");
const {
  initiateRegistration,
  verifyOtp,
  resendOtp,
  createPassword,
  checkRegistrationStatus,
} = require("../controllers/registrationController");
const {
  initiateActivation,
  verifyActivationOtp,
  completeActivation,
} = require("../controllers/activationController");
const { protect } = require("../middleware/auth");

const router = express.Router();

// Authentication
router.post("/login", login);
router.get("/me", protect, getMe);
router.post("/change-password", protect, changePassword);

// Registration & OTP
router.post("/register/initiate", initiateRegistration);
router.post("/register/verify-otp", verifyOtp);
router.post("/register/resend-otp", resendOtp);
router.post("/register/create-password", createPassword);
router.get("/registration-status/:phoneNumber", checkRegistrationStatus);

// First-Time Member Self-Service Activation Workflow
router.post("/activation/initiate", initiateActivation);
router.post("/activation/verify-otp", verifyActivationOtp);
router.post("/activation/complete", completeActivation);

module.exports = router;
