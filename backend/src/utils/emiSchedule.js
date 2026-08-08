const generateEmiSchedule = ({
  loanId,
  memberId,
  groupId,
  principalAmount,
  interestRate,
  tenureMonths,
  startDate,
  monthlyEmi,
}) => {
  const schedule = [];

  const start = new Date(startDate);

  for (let i = 1; i <= tenureMonths; i++) {
    const dueDate = new Date(start);

    dueDate.setMonth(dueDate.getMonth() + i);

    schedule.push({
      emiId: `${loanId}-EMI-${String(i).padStart(3, "0")}`,

      loanId,

      memberId,

      groupId,

      installmentNumber: i,

      amount: monthlyEmi,

      dueDate,

      status: "pending",

      paidDate: null,
    });
  }

  return schedule;
};

module.exports = {
  generateEmiSchedule,
};