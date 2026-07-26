import '../../domain/entities/user_entity.dart';

class UserRepository {
  static const String dummyPassword = "123456";

  static final List<UserEntity> users = [
    const UserEntity(
      id: 'SHG-001',
      name: 'Savitri Devi',
      phoneNumber: '9000000001',
      password: dummyPassword,
      role: UserRole.leader,
      position: UserPosition.president,
    ),
    const UserEntity(
      id: 'SHG-002',
      name: 'Lakshmi Devi',
      phoneNumber: '9000000002',
      password: dummyPassword,
      role: UserRole.leader,
      position: UserPosition.secretary,
    ),
    const UserEntity(
      id: 'SHG-003',
      name: 'Anasuya',
      phoneNumber: '9000000003',
      password: dummyPassword,
      role: UserRole.member,
      position: UserPosition.member,
    ),
    const UserEntity(
      id: 'SHG-004',
      name: 'Bhavani',
      phoneNumber: '9000000004',
      password: dummyPassword,
      role: UserRole.member,
      position: UserPosition.member,
    ),
    const UserEntity(
      id: 'SHG-005',
      name: 'Rajeshwari',
      phoneNumber: '9000000005',
      password: dummyPassword,
      role: UserRole.member,
      position: UserPosition.member,
    ),
    const UserEntity(
      id: 'SHG-006',
      name: 'Padma',
      phoneNumber: '9000000006',
      password: dummyPassword,
      role: UserRole.member,
      position: UserPosition.member,
    ),
    const UserEntity(
      id: 'SHG-007',
      name: 'Jyothi',
      phoneNumber: '9000000007',
      password: dummyPassword,
      role: UserRole.member,
      position: UserPosition.member,
    ),
    const UserEntity(
      id: 'SHG-008',
      name: 'Sujatha',
      phoneNumber: '9000000008',
      password: dummyPassword,
      role: UserRole.member,
      position: UserPosition.member,
    ),
    const UserEntity(
      id: 'SHG-009',
      name: 'Lalitha',
      phoneNumber: '9000000009',
      password: dummyPassword,
      role: UserRole.member,
      position: UserPosition.member,
    ),
    const UserEntity(
      id: 'SHG-010',
      name: 'Kavitha',
      phoneNumber: '9000000010',
      password: dummyPassword,
      role: UserRole.member,
      position: UserPosition.member,
    ),
  ];

  static UserEntity? findUser(String phone, String password) {
    try {
      return users.firstWhere(
        (u) => u.phoneNumber == phone && u.password == password,
      );
    } catch (_) {
      return null;
    }
  }
}
