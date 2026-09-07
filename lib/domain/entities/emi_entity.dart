class EmiEntity {
  final String id;
  final String loanId;
  final String memberId;
  final String memberName;
  final String groupId;
  final int installmentNumber;
  final double amount;
  final DateTime dueDate;
  final String status;
  final DateTime? paidDate;

  const EmiEntity({
    required this.id,
    required this.loanId,
    required this.memberId,
    required this.memberName,
    required this.groupId,
    required this.installmentNumber,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.paidDate,
  });

  bool get isOverdue => status == 'overdue';

  factory EmiEntity.fromJson(Map<String, dynamic> json) {
    final memberId = json['memberId']?.toString() ?? '';
    final paidDateValue = json['paidDate'];

    return EmiEntity(
      id: json['emiId']?.toString() ?? json['_id']?.toString() ?? '',
      loanId: json['loanId']?.toString() ?? '',
      memberId: memberId,
      memberName: json['memberName']?.toString() ?? memberId,
      groupId: json['groupId']?.toString() ?? '',
      installmentNumber: _parseInt(json['installmentNumber']),
      amount: _parseDouble(json['amount']),
      dueDate: _parseDate(json['dueDate']),
      status: json['status']?.toString() ?? 'pending',
      paidDate: paidDateValue == null
          ? null
          : DateTime.tryParse(paidDateValue.toString()),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static DateTime _parseDate(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
}
