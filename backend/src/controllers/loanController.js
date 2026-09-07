const Loan = require("../models/Loan");
const Emi = require("../models/Emi");
const { calculateMonthlyEmi } = require("../utils/emiCalculator");
const { generateEmiSchedule } = require("../utils/emiSchedule");

const getLoans = async (req, res) => {
  try {
    const { groupId, memberId } = req.query;
    const { role, groupId: userGroupId, userId } = req.user;

    const filter = {};

    // Enforce Group Access
    filter.groupId = userGroupId;

    // Enforce Member Access
    if (role === "member") {
      filter.memberId = userId;
    } else if (role === "leader") {
      if (memberId) filter.memberId = memberId;
    }

    const loans = await Loan.find(filter).sort({ createdAt: -1 });

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
      loanId,
      memberId,
      groupId,
      loanType,
      purpose,
      principalAmount,
      interestRate,
      tenureMonths,
      startDate,
    } = req.body;

    const { role, groupId: userGroupId } = req.user;

    // Only leaders can create loans
    if (role !== "leader") {
      return res.status(403).json({
        success: false,
        message: "Only group leaders can initiate loans",
      });
    }

    // Ensure loan is within the leader's group
    if (groupId !== userGroupId) {
      return res.status(403).json({
        success: false,
        message: "Cannot create loan for another group",
      });
    }

    if (!loanId || !memberId || !groupId || !purpose || principalAmount === undefined || interestRate === undefined || !tenureMonths || !startDate) {
      return res.status(400).json({
        success: false,
        message: "Required loan fields are missing",
      });
    }

    const existingLoan = await Loan.findOne({ loanId });
    if (existingLoan) {
      return res.status(409).json({
        success: false,
        message: "Loan ID already exists",
      });
    }

    const monthlyEmi = calculateMonthlyEmi(Number(principalAmount), Number(interestRate), Number(tenureMonths));

    const loan = await Loan.create({
      loanId,
      memberId,
      groupId,
      loanType: loanType || "SHG Bank Linkage",
      purpose,
      principalAmount: Number(principalAmount),
      interestRate: Number(interestRate),
      tenureMonths: Number(tenureMonths),
      startDate,
      status: "active",
    });

    const emiSchedule = generateEmiSchedule({
      loanId,
      memberId,
      groupId,
      principalAmount: Number(principalAmount),
      interestRate: Number(interestRate),
      tenureMonths: Number(tenureMonths),
      startDate,
      monthlyEmi,
    });

    await Emi.insertMany(emiSchedule);

    res.status(201).json({
      success: true,
      message: "Loan and EMI schedule created successfully",
      loan,
      emiSummary: {
        monthlyEmi,
        totalEmis: tenureMonths,
        firstDueDate: emiSchedule[0].dueDate,
        lastDueDate: emiSchedule[emiSchedule.length - 1].dueDate,
      },
    });
  } catch (error) {
    console.error("Create loan error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to create loan",
      error: error.message,
    });
  }
};

module.exports = {
  getLoans,
  createLoan,
};
