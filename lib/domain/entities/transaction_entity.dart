class TransactionEntity {
  final String id;
  final String transactionId;
  final String loanId;
  final String emiId;
  final String memberName;
  final String description;
  final double amount;
  final DateTime date;
  final String type; // 'Credit' or 'Debit'
  final String rawType; // 'loan_payment', etc.
  final String status; // 'completed', 'pending', 'failed'
  final int? installmentNumber;

  const TransactionEntity({
    required this.id,
    String? transactionId,
    this.loanId = '',
    this.emiId = '',
    required this.memberName,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
    this.rawType = 'loan_payment',
    this.status = 'completed',
    this.installmentNumber,
  }) : transactionId = transactionId ?? id;
}
