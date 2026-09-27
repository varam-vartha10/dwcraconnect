const Notification = require("../models/Notification");

const getNotifications = async (req, res) => {
  try {
    const { userId, groupId: userGroupId } = req.user;

    const notifications = await Notification.find({
      memberId: userId,
      groupId: userGroupId
    }).sort({ createdAt: -1 }).limit(20).lean();

    res.status(200).json({
      success: true,
      count: notifications.length,
      notifications,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: "Failed to fetch notifications" });
  }
};

const createNotification = async (req, res) => {
  try {
    const {
      notificationId,
      memberId,
      groupId,
      title,
      message,
      type,
      relatedId,
    } = req.body;

    const { role, groupId: userGroupId } = req.user;

    if (role !== "leader") {
      return res.status(403).json({
        success: false,
        message: "Only group leaders can create notifications",
      });
    }

    if (groupId !== userGroupId) {
      return res.status(403).json({
        success: false,
        message: "Cannot create notification for another group",
      });
    }

    if (!notificationId || !memberId || !groupId || !title || !message) {
      return res.status(400).json({
        success: false,
        message: "Required fields are missing",
      });
    }

    const existingNotif = await Notification.findOne({ notificationId });
    if (existingNotif) {
      return res.status(409).json({
        success: false,
        message: "Notification ID already exists",
      });
    }

    const notification = await Notification.create({
      notificationId,
      memberId,
      groupId,
      title,
      message,
      type,
      relatedId,
    });

    res.status(201).json({
      success: true,
      message: "Notification created successfully",
      notification,
    });
  } catch (error) {
    console.error("Create notification error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to create notification",
    });
  }
};

const markAsRead = async (req, res) => {
  try {
    const { notificationId } = req.params;
    await Notification.updateOne(
      { notificationId, memberId: req.user.userId },
      { $set: { isRead: true } }
    );
    res.status(200).json({ success: true });
  } catch (error) {
    res.status(500).json({ success: false, message: "Failed to mark as read" });
  }
};

module.exports = {
  getNotifications,
  createNotification,
  markAsRead,
};
