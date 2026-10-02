import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';
import '../../core/providers/auth_provider.dart';
import '../../data/repositories/emi_repository.dart';
import '../../data/repositories/loan_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/subsidy_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/loan_entity.dart';
import '../../domain/entities/emi_entity.dart';
import '../../domain/entities/subsidy_entity.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/member_entity.dart';
import '../../data/repositories/user_repository.dart';

final emiRepositoryProvider = Provider<EmiRepository>((ref) => EmiRepository());
final loanRepositoryProvider = Provider<LoanRepository>((ref) => LoanRepository());
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) => TransactionRepository());
final subsidyRepositoryProvider = Provider<SubsidyRepository>((ref) => SubsidyRepository());
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) => NotificationRepository());

final membersProvider = FutureProvider<List<MemberEntity>>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null) return [];

  if (user.role == UserRole.leader) {
    return UserRepository.getGroupMembersSummary(user.groupId);
  } else {
    return [
      MemberEntity(
        id: user.id,
        name: user.name,
        mobile: user.phoneNumber,
        aadhaar: user.aadhaar ?? '',
        village: user.village ?? '',
        shgGroup: user.groupId,
        loanAmount: 0,
        paidAmount: 0,
        remainingAmount: 0,
        emiAmount: 0,
        subsidyAmount: 0,
      )
    ];
  }
});

final currentMemberProvider = Provider<MemberEntity?>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return null;
  return MemberEntity(
    id: user.id,
    name: user.name,
    mobile: user.phoneNumber,
    aadhaar: '',
    village: user.village ?? '',
    shgGroup: user.groupId,
    loanAmount: 0,
    paidAmount: 0,
    remainingAmount: 0,
    emiAmount: 0,
    subsidyAmount: 0,
  );
});

final memberTransactionsProvider = FutureProvider<List<TransactionEntity>>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null) return [];
  return ref.watch(transactionRepositoryProvider).getTransactions(memberId: user.id);
});

final loansProvider = FutureProvider<List<LoanEntity>>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null) return [];
  
  final repository = ref.watch(loanRepositoryProvider);
  if (user.role == UserRole.leader) {
    return repository.getLoans(groupId: user.groupId);
  } else {
    return repository.getLoans(memberId: user.id);
  }
});

final emisProvider = FutureProvider<List<EmiEntity>>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null) return [];

  final repository = ref.watch(emiRepositoryProvider);
  if (user.role == UserRole.leader) {
    return repository.getEmis(groupId: user.groupId);
  }
  return repository.getEmis(memberId: user.id);
});

final transactionsProvider = FutureProvider<List<TransactionEntity>>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null) return [];
  
  final repository = ref.watch(transactionRepositoryProvider);
  if (user.role == UserRole.leader) {
    return repository.getTransactions(groupId: user.groupId);
  }
  return repository.getTransactions(memberId: user.id);
});

final subsidiesProvider = FutureProvider<List<SubsidyEntity>>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null) return [];

  final repository = ref.watch(subsidyRepositoryProvider);
  if (user.role == UserRole.leader) {
    return repository.getSubsidies(groupId: user.groupId);
  }
  return repository.getSubsidies(memberId: user.id);
});

final notificationsProvider = FutureProvider<List<NotificationEntity>>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null) return [];
  return ref.watch(notificationRepositoryProvider).getNotifications();
});

// Summary providers for dashboard performance
final loanSummaryProvider = FutureProvider<double>((ref) async {
  final loans = await ref.watch(loansProvider.future);
  double sum = 0;
  for (var loan in loans) {
    sum += loan.remainingAmount;
  }
  return sum;
});

final emiSummaryProvider = FutureProvider<double>((ref) async {
  final emis = await ref.watch(emisProvider.future);
  final pending = emis.where((e) => e.status == 'pending' || e.status == 'overdue').toList();
  return pending.isEmpty ? 0.0 : pending.first.amount;
});

final subsidySummaryProvider = FutureProvider<double>((ref) async {
  final subsidies = await ref.watch(subsidiesProvider.future);
  double sum = 0;
  for (var s in subsidies) {
    sum += s.amount;
  }
  return sum;
});
