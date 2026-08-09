const express = require("express");

const {
  getUsers,
  getUsersByGroup,
  createUser,
  migratePasswords,
} = require("../controllers/userController");

const router = express.Router();

// GET all users
router.get("/", getUsers);

// GET users of a particular group
router.get("/group/:groupId", getUsersByGroup);

// CREATE user
router.post("/", createUser);

// TEMPORARY password migration
router.post("/migrate-passwords", migratePasswords);

module.exports = router;