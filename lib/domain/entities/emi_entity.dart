class EmiEntity {
  final String id;
  final String memberName;
  final double amount;
  final DateTime dueDate;
  final bool isOverdue;

  const EmiEntity({
    required this.id,
    required this.memberName,
    required this.amount,
    required this.dueDate,
    required this.isOverdue,
  });
}
