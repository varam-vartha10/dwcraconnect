const Transaction = require("../models/Transaction");

const getTransactions = async (req, res) => {
  try {
    const { memberId, loanId, type } = req.query;
    const { role, groupId: userGroupId, userId } = req.user;

    const filter = { groupId: userGroupId };

    if (role === "member") {
      filter.memberId = userId;
    } else if (role === "leader" && memberId) {
      filter.memberId = memberId;
    }

    if (loanId) filter.loanId = loanId;
    if (type) filter.type = type;

    const transactions = await Transaction.find(filter).sort({ paymentDate: -1 }).limit(50).lean();

    res.status(200).json({
      success: true,
      count: transactions.length,
      transactions,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: "Failed to fetch transactions" });
  }
};

const createTransaction = async (req, res) => {
  try {
    const { transactionId, memberId, groupId, amount, type, status, paymentDate, notes } = req.body;
    const { role, groupId: userGroupId, userId } = req.user;

    if (role === "member" && memberId !== userId) {
      return res.status(403).json({ success: false, message: "Forbidden" });
    }

    const transaction = await Transaction.create({
      transactionId, memberId, groupId: userGroupId, amount, type,
      status: status || "pending", paymentDate, notes,
    });

    res.status(201).json({ success: true, transaction });
  } catch (error) {
    res.status(500).json({ success: false, message: "Failed" });
  }
};

module.exports = { getTransactions, createTransaction };
