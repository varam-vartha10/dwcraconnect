import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/auth/language_selection_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/registration_screen.dart';
import '../../features/auth/otp_verification_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/dashboard/member_dashboard_screen.dart';
import '../../features/dashboard/leader_dashboard_screen.dart';
import '../../features/dashboard/member_details_screen.dart';
import '../../features/dashboard/settings_screen.dart';
import '../../features/dashboard/training_hub_screen.dart';
import '../../features/loans/loan_balance_screen.dart';
import '../../features/loans/emi_details_screen.dart';
import '../../features/loans/active_loans_screen.dart';
import '../../features/loans/pending_emi_screen.dart';
import '../../features/loans/apply_loan_screen.dart';
import '../../features/ledger/transaction_history_screen.dart';
import '../../features/ledger/subsidy_details_screen.dart';
import '../../features/ledger/subsidy_records_screen.dart';
import '../../features/ledger/group_ledger_screen.dart';
import '../../features/ledger/add_transaction_screen.dart';
import '../../features/dashboard/notifications_screen.dart';
import '../../features/meetings/meeting_attendance_screen.dart';
import '../providers/auth_provider.dart';
import '../../domain/entities/user_entity.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.user != null;
      final isLeader = authState.user?.role == UserRole.leader;
      
      final publicRoutes = ['/', '/language-selection', '/login', '/register', '/otp-verification', '/forgot-password'];
      final leaderOnlyRoutes = [
        '/leader-dashboard', 
        '/member-details', 
        '/active-loans', 
        '/pending-emi', 
        '/subsidy-records', 
        '/group-ledger', 
        '/meeting-attendance'
      ];

      // If not logged in and trying to access a protected route
      if (!isLoggedIn && !publicRoutes.contains(state.uri.path) && !state.uri.path.startsWith('/member-details')) {
        return '/login';
      }

      // If logged in as member and trying to access leader routes
      if (isLoggedIn && !isLeader) {
        if (leaderOnlyRoutes.contains(state.uri.path) || state.uri.path.startsWith('/member-details')) {
          return '/member-dashboard';
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/language-selection', builder: (context, state) => const LanguageSelectionScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegistrationScreen()),
      GoRoute(
        path: '/otp-verification',
        builder: (context, state) {
          final phoneNumber = state.extra as String? ?? '';
          return OtpVerificationScreen(phoneNumber: phoneNumber);
        },
      ),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(path: '/member-dashboard', builder: (context, state) => const MemberDashboardScreen()),
      GoRoute(path: '/leader-dashboard', builder: (context, state) => const LeaderDashboardScreen()),
      GoRoute(
        path: '/member-details/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return MemberDetailsScreen(memberId: id);
        },
      ),
      GoRoute(path: '/loan-balance', builder: (context, state) => const LoanBalanceScreen()),
      GoRoute(path: '/emi-details', builder: (context, state) => const EmiDetailsScreen()),
      GoRoute(path: '/active-loans', builder: (context, state) => const ActiveLoansScreen()),
      GoRoute(path: '/pending-emi', builder: (context, state) => const PendingEmiScreen()),
      GoRoute(path: '/apply-loan', builder: (context, state) => const ApplyLoanScreen()),
      GoRoute(path: '/transaction-history', builder: (context, state) => const TransactionHistoryScreen()),
      GoRoute(path: '/subsidy-details', builder: (context, state) => const SubsidyDetailsScreen()),
      GoRoute(path: '/subsidy-records', builder: (context, state) => const SubsidyRecordsScreen()),
      GoRoute(path: '/group-ledger', builder: (context, state) => const GroupLedgerScreen()),
      GoRoute(path: '/add-transaction', builder: (context, state) => const AddTransactionScreen()),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(path: '/training-hub', builder: (context, state) => const TrainingHubScreen()),
      GoRoute(path: '/meeting-attendance', builder: (context, state) => const MeetingAttendanceScreen()),
      GoRoute(
        path: '/dashboard',
        redirect: (context, state) => '/login',
        builder: (context, state) => const SizedBox.shrink(),
      ),
    ],
  );
});
