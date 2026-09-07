const Notification = require("../models/Notification");

const getNotifications = async (req, res) => {
  try {
    const { isRead, type } = req.query;
    const { role, groupId: userGroupId, userId } = req.user;

    const filter = { groupId: userGroupId };

    // Members only see their own notifications
    // Leaders see group-level or their own notifications?
    // In SHG context, members usually only care about their own alerts.
    if (role === "member") {
      filter.memberId = userId;
    }

    if (isRead !== undefined) filter.isRead = isRead === "true";
    if (type) filter.type = type;

    const notifications = await Notification.find(filter).sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      count: notifications.length,
      notifications,
    });
  } catch (error) {
    console.error("Get notifications error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch notifications",
    });
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

    // Only leaders can broadcast/create notifications
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
    const { id } = req.params;
    const { userId } = req.user;

    const notification = await Notification.findOneAndUpdate(
      { notificationId: id, memberId: userId },
      { isRead: true },
      { new: true }
    );

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: "Notification not found or not owned by user",
      });
    }

    res.status(200).json({
      success: true,
      notification,
    });
  } catch (error) {
    console.error("Mark as read error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to mark notification as read",
    });
  }
};

module.exports = {
  getNotifications,
  createNotification,
  markAsRead,
};
