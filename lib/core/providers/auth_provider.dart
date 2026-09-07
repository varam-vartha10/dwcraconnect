import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user_entity.dart';
import '../../data/repositories/user_repository.dart';
import 'navigation_provider.dart';

class AuthState {
  final UserEntity? user;
  final bool isLoading;
  final String? errorMessage;
  final bool isInitialized;

  AuthState({
    this.user, 
    this.isLoading = false, 
    this.errorMessage,
    this.isInitialized = false,
  });

  AuthState copyWith({
    UserEntity? user, 
    bool? isLoading, 
    String? errorMessage,
    bool? isInitialized,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  AuthNotifier(this._ref) : super(AuthState()) {
    _init();
  }

  static const String _userPhoneKey = 'logged_in_user_phone';

  Future<void> _init() async {
  final prefs = await SharedPreferences.getInstance();

  final phone = prefs.getString(_userPhoneKey);

  if (phone != null) {
    // We will implement token/session restoration
    // after the basic API login is working.
    state = state.copyWith(
      isInitialized: true,
    );
  } else {
    state = state.copyWith(
      isInitialized: true,
    );
  }
}


Future<UserRole> login(
  String phoneNumber,
  String password,
) async {
  state = state.copyWith(
    isLoading: true,
    errorMessage: null,
  );

  try {
    final user = await UserRepository.login(
      phoneNumber,
      password,
    );

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _userPhoneKey,
      user.phoneNumber,
    );

    state = AuthState(
      user: user,
      isLoading: false,
      isInitialized: true,
    );

    // Reset navigation after login
    if (user.role == UserRole.leader) {
      _ref
          .read(leaderBottomNavIndexProvider.notifier)
          .state = 0;
    } else {
      _ref
          .read(memberBottomNavIndexProvider.notifier)
          .state = 0;
    }

    return user.role;
  } catch (error) {
    state = state.copyWith(
      isLoading: false,
      errorMessage: error
          .toString()
          .replaceFirst('Exception: ', ''),
    );

    return UserRole.unknown;
  }
}

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userPhoneKey);
    
    state = AuthState(isInitialized: true);
    // Reset indices on logout
    _ref.read(leaderBottomNavIndexProvider.notifier).state = 0;
    _ref.read(memberBottomNavIndexProvider.notifier).state = 0;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
