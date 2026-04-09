import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_service_providers.dart';

final adminAuthStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(adminAuthServiceProvider).authStateChanges;
});

final adminRoleProvider = FutureProvider<bool>((ref) async {
  final userAsync = ref.watch(adminAuthStateProvider);
  final user = userAsync.valueOrNull;
  if (user == null) return false;
  return ref.read(adminAuthServiceProvider).isAdmin(user.uid);
});
