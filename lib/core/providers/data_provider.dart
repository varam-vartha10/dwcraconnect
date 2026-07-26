import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';
import '../../core/providers/auth_provider.dart';
import '../../data/repositories/mock_repository.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/loan_entity.dart';
import '../../domain/entities/emi_entity.dart';
import '../../domain/entities/subsidy_entity.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/member_entity.dart';

final membersProvider = Provider<List<MemberEntity>>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return [];
  if (user.role == UserRole.leader) return MockRepository.members;
  
  // Member role: return only own member data
  return MockRepository.members.where((m) => m.mobile == user.phoneNumber).toList();
});

final currentMemberProvider = Provider<MemberEntity?>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return null;

  final matches = MockRepository.members.where((member) => member.mobile == user.phoneNumber).toList();
  return matches.isEmpty ? null : matches.first;
});

final memberTransactionsProvider = Provider<List<TransactionEntity>>((ref) {
  final member = ref.watch(currentMemberProvider);
  if (member == null) return [];
  // For members, we strictly only show their own transactions
  return MockRepository.transactions.where((tx) => tx.description.contains(member.name.split(' ')[0])).toList();
});

final transactionsProvider = Provider<List<TransactionEntity>>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return [];
  if (user.role == UserRole.leader) return MockRepository.transactions;
  
  // Member role: filter transactions by name (hacky since mock doesn't have memberId on tx)
  final member = ref.read(currentMemberProvider);
  if (member == null) return [];
  return MockRepository.transactions.where((tx) => tx.description.contains(member.name.split(' ')[0])).toList();
});

final loansProvider = Provider<List<LoanEntity>>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return [];
  if (user.role == UserRole.leader) return MockRepository.loans;

  // Member role: return only own loan
  final member = ref.read(currentMemberProvider);
  if (member == null) return [];
  return MockRepository.loans.where((loan) => loan.memberName == member.name).toList();
});

final emisProvider = Provider<List<EmiEntity>>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return [];
  if (user.role == UserRole.leader) return MockRepository.emis;

  // Member role: return only own emis
  final member = ref.read(currentMemberProvider);
  if (member == null) return [];
  return MockRepository.emis.where((emi) => emi.memberName == member.name).toList();
});

final subsidiesProvider = Provider<List<SubsidyEntity>>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return [];
  if (user.role == UserRole.leader) return MockRepository.subsidies;

  // Member role: return only own subsidies
  final member = ref.read(currentMemberProvider);
  if (member == null) return [];
  return MockRepository.subsidies.where((subsidy) => subsidy.memberName == member.name).toList();
});

final notificationsProvider = StateProvider<List<NotificationEntity>>((ref) {
  return MockRepository.notifications;
});
