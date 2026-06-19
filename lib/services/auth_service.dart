import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../utils/constants.dart';
import 'notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Register
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

    return user;
  }

  // Login
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

    final appUser = AppUser.fromMap(doc.data()!, doc.id);
    await NotificationService.loginUser(appUser.uid);
    return appUser;
  }

  // Get current AppUser
  Future<AppUser?> getCurrentAppUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    final doc = await _db
        .collection(AppConstants.usersCol)
        .doc(firebaseUser.uid)
        .get();

    if (!doc.exists) return null;
    return AppUser.fromMap(doc.data()!, doc.id);
  }

  // Resend Verification
  Future<String?> resendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
      return null; // success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        return 'Too many attempts. Please wait a few minutes and try again.';
      }
      return e.message ?? 'Failed to send email.';
    } catch (e) {
      return 'Something went wrong.';
    }
  }

  // Refresh email verified status
  Future<bool> checkEmailVerified() async {
    try {
      await _auth.currentUser?.reload();
      return _auth.currentUser?.emailVerified ?? false;
    } catch (_) {
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await NotificationService.logoutUser();
    await _auth.signOut();
  }

  // Forgot Password
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
