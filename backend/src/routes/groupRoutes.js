const express = require("express");
const { protect } = require("../middleware/auth");
const {
  getGroups,
  createGroup,
} = require("../controllers/groupController");

const router = express.Router();

router.get("/", protect, getGroups);
router.post("/", createGroup);

module.exports = router;
