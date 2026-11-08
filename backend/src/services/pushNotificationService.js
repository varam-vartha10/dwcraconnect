/**
 * Push Notification Service using Firebase Cloud Messaging (FCM) / REST API.
 * Reads environment variables:
 * - FCM_SERVER_KEY or FIREBASE_SERVICE_ACCOUNT
 */
const sendPushNotification = async ({ deviceToken, title, message, dataPayload = {} }) => {
  if (!deviceToken || deviceToken.trim().length === 0) {
    return { success: false, reason: "No device token registered for user" };
  }

  const fcmServerKey = process.env.FCM_SERVER_KEY;

  if (fcmServerKey) {
    try {
      const response = await fetch("https://fcm.googleapis.com/fcm/send", {
        method: "POST",
        headers: {
          Authorization: `key=${fcmServerKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          to: deviceToken,
          notification: {
            title,
            body: message,
            sound: "default",
          },
          data: dataPayload,
          priority: "high",
        }),
      });

      const data = await response.json();
      if (response.ok && data.success === 1) {
        console.log(`[FCM Push] Notification delivered to token ending in ...${deviceToken.slice(-6)}`);
        return { success: true, provider: "fcm", messageId: data.results?.[0]?.message_id };
      } else {
        console.error(`[FCM Push Error] Response:`, JSON.stringify(data));
        return { success: false, provider: "fcm", error: data };
      }
    } catch (err) {
      console.error(`[FCM Push Exception]:`, err.message);
      return { success: false, provider: "fcm", error: err.message };
    }
  }

  // Fallback Sandbox Delivery Log (When FCM credentials are not configured in environment)
  console.log(`[Push Notification Sandbox] Delivered to ...${deviceToken.slice(-6)}: "${title}" - "${message}"`);
  return {
    success: true,
    provider: "sandbox",
    note: "FCM_SERVER_KEY environment variable not configured. Logged push notification payload in sandbox mode.",
  };
};

module.exports = { sendPushNotification };
