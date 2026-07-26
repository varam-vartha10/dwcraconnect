enum UserRole { member, leader, unknown }

enum UserPosition { president, secretary, member }

class UserEntity {
  final String id;
  final String name;
  final String phoneNumber;
  final String password;
  final UserRole role;
  final UserPosition position;

  const UserEntity({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.password,
    required this.role,
    required this.position,
  });
}
