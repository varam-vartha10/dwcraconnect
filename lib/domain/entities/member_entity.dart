class MemberEntity {
  final String id;
  final String name;
  final String mobile;
  final String aadhaar;
  final String village;
  final String shgGroup;
  final double loanAmount;
  final double paidAmount;
  final double remainingAmount;
  final double emiAmount;
  final double subsidyAmount;

  const MemberEntity({
    required this.id,
    required this.name,
    required this.mobile,
    required this.aadhaar,
    required this.village,
    required this.shgGroup,
    required this.loanAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.emiAmount,
    required this.subsidyAmount,
  });

  double get repaymentProgress => loanAmount > 0 ? (paidAmount / loanAmount) : 0.0;
}
