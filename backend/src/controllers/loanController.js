const Loan = require("../models/Loan");
const Emi = require("../models/Emi");

const {
  calculateMonthlyEmi,
} = require("../utils/emiCalculator");

const {
  generateEmiSchedule,
} = require("../utils/emiSchedule");


// GET /api/loans
// Optional:
// /api/loans?groupId=GRP001
// /api/loans?memberId=SHG-003
const getLoans = async (req, res) => {
  try {
    const { groupId, memberId } = req.query;

    const filter = {};

    if (groupId) {
      filter.groupId = groupId;
    }

    if (memberId) {
      filter.memberId = memberId;
    }

    const loans = await Loan.find(filter).sort({
      createdAt: -1,
    });

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


// POST /api/loans
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


    // Validate required fields
    if (
      !loanId ||
      !memberId ||
      !groupId ||
      !purpose ||
      principalAmount === undefined ||
      interestRate === undefined ||
      !tenureMonths ||
      !startDate
    ) {
      return res.status(400).json({
        success: false,
        message: "Required loan fields are missing",
      });
    }


    // Check whether loan ID already exists
    const existingLoan = await Loan.findOne({ loanId });

    if (existingLoan) {
      return res.status(409).json({
        success: false,
        message: "Loan ID already exists",
      });
    }


    // Calculate monthly EMI
    const monthlyEmi = calculateMonthlyEmi(
      Number(principalAmount),
      Number(interestRate),
      Number(tenureMonths)
    );


    // Create loan
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


    // Generate EMI schedule
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


    // Save all EMI records
    await Emi.insertMany(emiSchedule);


    // Send response
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