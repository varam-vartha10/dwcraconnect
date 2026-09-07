const express = require("express");
const { protect, authorize } = require("../middleware/auth");
const {
  getUsers,
  getUsersByGroup,
  createUser,
  migratePasswords,
} = require("../controllers/userController");

const router = express.Router();

// GET all users
router.get("/", protect, authorize("leader"), getUsers);

// GET users of a particular group
router.get("/group/:groupId", protect, getUsersByGroup);

// CREATE user (Usually leaders create members, or admin creates groups)
router.post("/", createUser);

// TEMPORARY password migration
router.post("/migrate-passwords", migratePasswords);

module.exports = router;
