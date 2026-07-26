class TransactionEntity {
  final String id;
  final String memberName;
  final String description;
  final double amount;
  final DateTime date;
  final String type; // 'Credit' or 'Debit'

  const TransactionEntity({
    required this.id,
    required this.memberName,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
  });
}
