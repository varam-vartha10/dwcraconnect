const express = require("express");
const { protect, authorize } = require("../middleware/auth");
const {
  getUsers,
  getUsersByGroup,
  createUser,
  updateUser,
  migratePasswords,
} = require("../controllers/userController");

const router = express.Router();

// GET all users
router.get("/", protect, authorize("leader"), getUsers);

// GET users of a particular group
router.get("/group/:groupId", protect, getUsersByGroup);

// CREATE user
router.post("/", createUser);

// UPDATE profile
router.patch("/profile", protect, updateUser);

// TEMPORARY password migration
router.post("/migrate-passwords", migratePasswords);

module.exports = router;
