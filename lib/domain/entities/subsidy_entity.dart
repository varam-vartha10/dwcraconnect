class SubsidyEntity {
  final String id;
  final String memberName;
  final String schemeName;
  final double amount;
  final DateTime date;
  final String status;

  const SubsidyEntity({
    required this.id,
    required this.memberName,
    required this.schemeName,
    required this.amount,
    required this.date,
    required this.status,
  });
}
