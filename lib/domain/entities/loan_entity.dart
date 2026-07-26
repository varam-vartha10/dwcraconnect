class LoanEntity {
  final String id;
  final String memberName;
  final double totalAmount;
  final double remainingAmount;
  final String status;
  final double interestRate;
  final String type;

  const LoanEntity({
    required this.id,
    required this.memberName,
    required this.totalAmount,
    required this.remainingAmount,
    required this.status,
    required this.interestRate,
    required this.type,
  });

  double get paidAmount => totalAmount - remainingAmount;
  double get progress => paidAmount / totalAmount;
}
