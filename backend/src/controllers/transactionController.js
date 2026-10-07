const Transaction = require("../models/Transaction");
const Emi = require("../models/Emi");

const getTransactions = async (req, res) => {
  try {
    let { memberId, loanId, type, page = 1, limit = 20 } = req.query;
    const { role, groupId: userGroupId, userId } = req.user;

    page = Math.max(1, parseInt(page) || 1);
    limit = Math.min(50, Math.max(1, parseInt(limit) || 20));

    const filter = { groupId: userGroupId };

    // Strict Member Isolation
    if (role === "member") {
      filter.memberId = userId;
    } else if (role === "leader" && memberId) {
      filter.memberId = memberId;
    }

    if (loanId) filter.loanId = loanId;
    if (type) filter.type = type;

    const totalTransactions = await Transaction.countDocuments(filter);
    const totalPages = Math.ceil(totalTransactions / limit) || 1;

    const rawTxs = await Transaction.find(filter)
      .sort({ paymentDate: -1, createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit)
      .lean();

    // Enrich transactions with EMI installment number if linked
    const transactions = await Promise.all(
      rawTxs.map(async (t) => {
        let installmentNumber = null;
        if (t.emiId) {
          const emi = await Emi.findOne({ emiId: t.emiId }).select("installmentNumber").lean();
          if (emi) installmentNumber = emi.installmentNumber;
        }
        return {
          ...t,
          installmentNumber,
        };
      })
    );

    res.status(200).json({
      success: true,
      count: transactions.length,
      page,
      totalPages,
      totalTransactions,
      transactions,
    });
  } catch (error) {
    console.error("Get transactions error:", error.message);
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
      transactionId,
      memberId: role === "member" ? userId : memberId,
      groupId: userGroupId,
      amount,
      type: type || "loan_payment",
      status: status || "completed",
      paymentDate: paymentDate || new Date(),
      notes: notes || "",
    });

    res.status(201).json({ success: true, transaction });
  } catch (error) {
    console.error("Create transaction error:", error.message);
    res.status(500).json({ success: false, message: "Failed to create transaction" });
  }
};

module.exports = { getTransactions, createTransaction };
