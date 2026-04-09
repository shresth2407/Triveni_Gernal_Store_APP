import 'package:firebase_auth/firebase_auth.dart';

enum AdminAuthStatus {
  unknown,
  unauthenticated,
  authenticating,
  authenticated,
  notAdmin,
}

class AdminState {
  final AdminAuthStatus status;
  final String? errorMessage;
  final User? user;

  const AdminState({
    required this.status,
    this.errorMessage,
    this.user,
  });

  const AdminState.initial()
      : status = AdminAuthStatus.unknown,
        errorMessage = null,
        user = null;

  AdminState copyWith({
    AdminAuthStatus? status,
    String? errorMessage,
    User? user,
  }) {
    return AdminState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      user: user ?? this.user,
    );
  }
}
