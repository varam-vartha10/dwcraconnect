class UserModel {
  final String userId;
  final String groupId;
  final String name;
  final String phoneNumber;
  final String role;
  final String position;
  final String? aadhaar;
  final String? village;
  final bool isActive;

  UserModel({
    required this.userId,
    required this.groupId,
    required this.name,
    required this.phoneNumber,
    required this.role,
    required this.position,
    this.aadhaar,
    this.village,
    required this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] ?? '',
      groupId: json['groupId'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      role: json['role'] ?? '',
      position: json['position'] ?? '',
      aadhaar: json['aadhaar'],
      village: json['village'],
      isActive: json['isActive'] ?? true,
    );
  }
}