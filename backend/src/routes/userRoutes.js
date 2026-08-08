const express = require("express");

const {
  getUsers,
  getUsersByGroup,
  createUser,
} = require("../controllers/userController");

const router = express.Router();

// GET all users
router.get("/", getUsers);

// GET users of a particular group
router.get("/group/:groupId", getUsersByGroup);

// CREATE user
router.post("/", createUser);

module.exports = router;