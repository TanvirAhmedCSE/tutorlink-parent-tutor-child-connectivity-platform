import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../utils/constants.dart';
import 'hive_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  //  Register
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? parentType,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Send verification email
    await cred.user!.sendEmailVerification();

    final user = AppUser(
      uid: cred.user!.uid,
      name: name,
      email: email,
      role: role,
      createdAt: DateTime.now(),
      parentType: parentType,
    );

    await _db
        .collection(AppConstants.usersCol)
        .doc(cred.user!.uid)
        .set(user.toMap());

    await HiveService.saveUser(user);
    return user;
  }

  //  Login
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final doc = await _db
        .collection(AppConstants.usersCol)
        .doc(cred.user!.uid)
        .get();

    if (!doc.exists) throw Exception('User data not found');

    final user = AppUser.fromMap(doc.data()!, doc.id);
    await HiveService.saveUser(user);
    return user;
  }

  //  Get current AppUser
  Future<AppUser?> getCurrentAppUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    // Try Hive cache first
    final cached = HiveService.getUser();
    if (cached != null) return cached;

    final doc = await _db
        .collection(AppConstants.usersCol)
        .doc(firebaseUser.uid)
        .get();

    if (!doc.exists) return null;
    final user = AppUser.fromMap(doc.data()!, doc.id);
    await HiveService.saveUser(user);
    return user;
  }

  //  Resend Verification
  Future<void> resendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  //  Refresh email verified status
  Future<bool> checkEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  //  Logout
  Future<void> logout() async {
    await HiveService.clearAll();
    await _auth.signOut();
  }

  //  Forgot Password
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
