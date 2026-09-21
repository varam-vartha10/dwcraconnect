const Loan = require("../models/Loan");
const Emi = require("../models/Emi");
const { calculateMonthlyEmi } = require("../utils/emiCalculator");
const { generateEmiSchedule } = require("../utils/emiSchedule");

const getLoans = async (req, res) => {
  try {
    const { memberId } = req.query;
    const { role, groupId: userGroupId, userId } = req.user;

    const filter = { groupId: userGroupId };

    if (role === "member") {
      filter.memberId = userId;
    } else if (role === "leader" && memberId) {
      filter.memberId = memberId;
    }

    const loans = await Loan.find(filter).sort({ createdAt: -1 }).lean();

    res.status(200).json({
      success: true,
      count: loans.length,
      loans,
    });
  } catch (error) {
    console.error("Get loans error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch loans",
    });
  }
};

const createLoan = async (req, res) => {
  try {
    const {
      loanId, memberId, groupId, loanType, purpose,
      principalAmount, interestRate, tenureMonths, startDate,
    } = req.body;

    const { role, groupId: userGroupId } = req.user;

    if (role !== "leader") {
      return res.status(403).json({ success: false, message: "Only leaders can initiate loans" });
    }

    if (groupId !== userGroupId) {
      return res.status(403).json({ success: false, message: "Cannot create loan for another group" });
    }

    const monthlyEmi = calculateMonthlyEmi(Number(principalAmount), Number(interestRate), Number(tenureMonths));

    const loan = await Loan.create({
      loanId, memberId, groupId, loanType: loanType || "SHG Bank Linkage",
      purpose, principalAmount: Number(principalAmount), interestRate: Number(interestRate),
      tenureMonths: Number(tenureMonths), startDate, status: "active",
    });

    const emiSchedule = generateEmiSchedule({
      loanId, memberId, groupId, principalAmount: Number(principalAmount),
      interestRate: Number(interestRate), tenureMonths: Number(tenureMonths),
      startDate, monthlyEmi,
    });

    await Emi.insertMany(emiSchedule);

    res.status(201).json({ success: true, message: "Loan created", loan });
  } catch (error) {
    res.status(500).json({ success: false, message: "Failed to create loan" });
  }
};

module.exports = { getLoans, createLoan };
