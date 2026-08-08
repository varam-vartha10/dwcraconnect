const calculateMonthlyEmi = (
  principal,
  annualInterestRate,
  tenureMonths
) => {
  if (principal <= 0) {
    throw new Error("Principal amount must be greater than 0");
  }

  if (tenureMonths <= 0) {
    throw new Error("Tenure must be greater than 0");
  }

  // 0% interest
  if (annualInterestRate === 0) {
    return Number((principal / tenureMonths).toFixed(2));
  }

  // Convert annual percentage to monthly decimal
  const monthlyRate = annualInterestRate / 12 / 100;

  const emi =
    (principal *
      monthlyRate *
      Math.pow(1 + monthlyRate, tenureMonths)) /
    (Math.pow(1 + monthlyRate, tenureMonths) - 1);

  return Number(emi.toFixed(2));
};

module.exports = {
  calculateMonthlyEmi,
};