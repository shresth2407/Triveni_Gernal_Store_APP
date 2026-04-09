import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthService {
  Stream<User?> get authStateChanges;
  Future<void> signUp(String email, String password);
  Future<void> signIn(String email, String password);
  Future<void> signOut();
  User? get currentUser;
}

class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<void> signUp(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  User? get currentUser => _auth.currentUser;
}
