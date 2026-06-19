import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/auth_service.dart';
import 'utils/theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/auth/setup_profile_picture_screen.dart';
import 'screens/shell/main_shell.dart';
import 'models/models.dart';
import 'firebase_options.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/notification_service.dart';
import 'screens/assignments/assignment_detail_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.init();

  runApp(const TutorLinkApp());
}

class TutorLinkApp extends StatelessWidget {
  const TutorLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TutorLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const _AppWrapper(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const _AppWrapper(),
      },
    );
  }
}

class _AppWrapper extends StatefulWidget {
  const _AppWrapper();

  @override
  State<_AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<_AppWrapper> {
  @override
  void initState() {
    super.initState();
    _setupNotificationTap();
  }

  void _setupNotificationTap() {
    OneSignal.Notifications.addClickListener((event) async {
      final data = event.notification.additionalData;
      if (data == null) return;

      final assignmentId = data['assignmentId'] as String?;
      if (assignmentId == null) return;

      await _goToAssignment(assignmentId);
    });
  }

  Future<void> _goToAssignment(String assignmentId) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    final assignDoc = await FirebaseFirestore.instance
        .collection(AppConstants.assignmentsCol)
        .doc(assignmentId)
        .get();
    if (!assignDoc.exists) return;

    final userDoc = await FirebaseFirestore.instance
        .collection(AppConstants.usersCol)
        .doc(firebaseUser.uid)
        .get();
    if (!userDoc.exists) return;

    final assignment = Assignment.fromMap(assignDoc.data()!, assignDoc.id);
    final currentUser = AppUser.fromMap(userDoc.data()!, userDoc.id);

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AssignmentDetailScreen(
            assignment: assignment,
            currentUser: currentUser,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }
        if (snapshot.data == null) return const LoginScreen();
        final firebaseUser = snapshot.data!;
        if (!firebaseUser.emailVerified) return const VerifyEmailScreen();
        return _UserLoader(firebaseUser: firebaseUser);
      },
    );
  }
}

class _UserLoader extends StatefulWidget {
  final User firebaseUser;
  const _UserLoader({required this.firebaseUser});

  @override
  State<_UserLoader> createState() => _UserLoaderState();
}

class _UserLoaderState extends State<_UserLoader> {
  final _auth = AuthService();
  AppUser? _user;
  bool _error = false;
  bool _avatarSaved = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _auth.getCurrentAppUser();
      if (mounted) {
        if (user != null) {
          setState(() => _user = user);
        } else {
          setState(() => _error = true);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              const Text('Failed to load user data'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await _auth.logout();
                  if (mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      );
    }

    if (_user == null) {
      return const _SplashScreen();
    }

    if (!_avatarSaved &&
        (_user!.avatarUrl == null || _user!.avatarUrl!.isEmpty)) {
      return SetupProfilePictureScreen(
        user: _user!,
        onAvatarSaved: () => setState(() => _avatarSaved = true),
      );
    }

    return MainShell(user: _user!);
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 42,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'TutorLink',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Parent · Teacher · Child',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}
