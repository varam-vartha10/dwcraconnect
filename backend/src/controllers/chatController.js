const { processChatMessage, ChatServiceError } = require("../services/chatService");

const MAX_MESSAGE_LENGTH = 1000;

const sendChatMessage = async (req, res) => {
  try {
    const { message } = req.body || {};

    if (typeof message !== "string") {
      return res.status(400).json({
        success: false,
        message: "Message must be a text value.",
      });
    }

    const sanitizedMessage = message.replace(/\u0000/g, "").trim();

    if (!sanitizedMessage) {
      return res.status(400).json({
        success: false,
        message: "Message cannot be empty.",
      });
    }

    if (sanitizedMessage.length > MAX_MESSAGE_LENGTH) {
      return res.status(400).json({
        success: false,
        message: `Message must not exceed ${MAX_MESSAGE_LENGTH} characters.`,
      });
    }

    const result = await processChatMessage({
      authenticatedUser: req.user,
      message: sanitizedMessage,
    });

    return res.status(200).json({
      success: true,
      reply: result.reply,
      language: result.language,
      intent: result.intent,
      dataSource: result.dataSource
    });
  } catch (error) {
    if (error instanceof ChatServiceError) {
      return res.status(error.statusCode).json({
        success: false,
        message: error.message,
      });
    }

    console.error("Chat request failed:", error.name, error.message);
    return res.status(500).json({
      success: false,
      message: "Unable to process your request.",
    });
  }
};

module.exports = { sendChatMessage };
