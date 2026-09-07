const Transaction = require("../models/Transaction");

const getTransactions = async (req, res) => {
  try {
    const { memberId, loanId, emiId, type } = req.query;
    const { role, groupId: userGroupId, userId } = req.user;

    const filter = { groupId: userGroupId };

    if (role === "member") {
      filter.memberId = userId;
    } else if (role === "leader") {
      if (memberId) filter.memberId = memberId;
    }

    if (loanId) filter.loanId = loanId;
    if (emiId) filter.emiId = emiId;
    if (type) filter.type = type;

    const transactions = await Transaction.find(filter).sort({ paymentDate: -1 });

    res.status(200).json({
      success: true,
      count: transactions.length,
      transactions,
    });
  } catch (error) {
    console.error("Get transactions error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch transactions",
    });
  }
};

const createTransaction = async (req, res) => {
  try {
    const {
      transactionId,
      loanId,
      emiId,
      memberId,
      groupId,
      amount,
      type,
      status,
      paymentDate,
      notes,
    } = req.body;

    const { role, groupId: userGroupId, userId } = req.user;

    // Normal members can only create their own transactions (e.g. initiating a payment)
    if (role === "member" && memberId !== userId) {
      return res.status(403).json({
        success: false,
        message: "Cannot create transaction for another member",
      });
    }

    if (groupId !== userGroupId) {
      return res.status(403).json({
        success: false,
        message: "Cannot create transaction for another group",
      });
    }

    if (!transactionId || !memberId || !groupId || amount === undefined || !type) {
      return res.status(400).json({
        success: false,
        message: "Required fields are missing",
      });
    }

    const existingTx = await Transaction.findOne({ transactionId });
    if (existingTx) {
      return res.status(409).json({
        success: false,
        message: "Transaction ID already exists",
      });
    }

    const transaction = await Transaction.create({
      transactionId,
      loanId,
      emiId,
      memberId,
      groupId,
      amount,
      type,
      status: status || "pending",
      paymentDate,
      notes,
    });

    res.status(201).json({
      success: true,
      message: "Transaction created successfully",
      transaction,
    });
  } catch (error) {
    console.error("Create transaction error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to create transaction",
    });
  }
};

module.exports = {
  getTransactions,
  createTransaction,
};
