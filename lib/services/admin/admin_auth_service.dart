import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class AdminAuthService {
  Future<void> signIn(String email, String password);
  Future<bool> isAdmin(String uid);
  Future<void> signOut();
  User? get currentUser;
  Stream<User?> get authStateChanges;
}

class FirebaseAdminAuthService implements AdminAuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseAdminAuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<bool> isAdmin(String uid) async {
    final doc = await _firestore.collection('admins').doc(uid).get();
    return doc.exists;
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
