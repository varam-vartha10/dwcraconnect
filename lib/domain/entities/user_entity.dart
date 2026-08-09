enum UserRole {
  member,
  leader,
  unknown,
}

enum UserPosition {
  president,
  secretary,
  member,
}

class UserEntity {
  final String id;
  final String groupId;
  final String name;
  final String phoneNumber;
  final UserRole role;
  final UserPosition position;

  const UserEntity({
    required this.id,
    required this.groupId,
    required this.name,
    required this.phoneNumber,
    required this.role,
    required this.position,
  });
}