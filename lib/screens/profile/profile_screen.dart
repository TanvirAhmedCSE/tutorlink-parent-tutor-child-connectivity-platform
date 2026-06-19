import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';
import '../../widgets/widgets.dart';
import '../auth/setup_profile_picture_screen.dart';
import '../progress/student_progress_screen.dart';
import '../../utils/constants.dart';

class ProfileScreen extends StatelessWidget {
  final AppUser user;
  const ProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: FirestoreService().userStream(user.uid),
      builder: (context, snap) {
        final current = snap.data ?? user;
        switch (current.role) {
          case UserRole.parent:
            return _ParentProfile(user: current);
          case UserRole.teacher:
            return _TeacherProfile(user: current);
          case UserRole.child:
            return _ChildProfile(user: current);
        }
      },
    );
  }
}

//  Shared Profile Header

class _ProfileHeader extends StatelessWidget {
  final AppUser user;

  const _ProfileHeader({required this.user});

  Color get _roleColor {
    switch (user.role) {
      case UserRole.parent:
        return AppColors.parentColor;
      case UserRole.teacher:
        return AppColors.teacherColor;
      case UserRole.child:
        return AppColors.childColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // rectangle avatar instead of circle
          RectAvatar(
            imagePath: user.avatarUrl,
            name: user.name,
            width: 88,
            height: 112,
            borderRadius: 18,
          ),
          const SizedBox(height: 12),
          // change picture button
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    SetupProfilePictureScreen(user: user, isUpdate: true),
              ),
            ),
            icon: const Icon(Icons.edit_outlined, size: 15),
            label: const Text('Change Profile Picture'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              textStyle: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          RoleBadge(label: user.role.label, color: _roleColor),
          if (user.role == UserRole.parent && user.parentType != null) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  user.parentType == 'father' ? Icons.male : Icons.female,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  user.parentType == 'father' ? 'Father' : 'Mother',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

//  Parent Profile

class _ParentProfile extends StatelessWidget {
  final AppUser user;
  final _fs = FirestoreService();
  final _auth = AuthService();

  _ParentProfile({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _ProfileHeader(user: user),
            const Divider(),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SectionHeader(
                title: 'My Children',
                action: TextButton.icon(
                  onPressed: () => _showAddLinkSheet(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Link'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Child>>(
              stream: _fs.parentChildrenStream(user.uid),
              builder: (context, snap) {
                final children = snap.data ?? [];
                if (children.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: EmptyState(
                      icon: Icons.child_care_rounded,
                      title: 'No children linked',
                      subtitle:
                          'Tap "Add Link" to connect a teacher & student.',
                    ),
                  );
                }
                return Column(
                  children: children
                      .map((c) => _ChildListTile(child: c))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SectionHeader(title: 'Linked Teachers'),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<TeacherChildLink>>(
              stream: _fs.parentLinksStream(user.uid),
              builder: (context, snap) {
                final links = snap.data ?? [];
                if (links.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Text(
                      'No teachers linked yet.',
                      style: TextStyle(color: AppColors.textHint),
                    ),
                  );
                }
                final seen = <String>{};
                final unique = links
                    .where((l) => seen.add(l.teacherId))
                    .toList();
                return Column(
                  children: unique
                      .map(
                        (l) => ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          leading: RectAvatar(
                            imagePath: l.teacherAvatarUrl.isNotEmpty
                                ? l.teacherAvatarUrl
                                : null,
                            name: l.teacherName,
                            width: 36,
                            height: 46,
                            borderRadius: 8,
                          ),
                          title: Text(
                            l.teacherName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            l.subject,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 8),
            const Divider(),
            _buildSettings(context),
          ],
        ),
      ),
    );
  }

  void _showAddLinkSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ParentAddLinkSheet(parent: user),
    );
  }

  Widget _buildSettings(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        _SettingsTile(
          icon: Icons.notifications_outlined,
          label: 'Notifications',
          onTap: () {},
        ),
        _SettingsTile(
          icon: Icons.info_outline_rounded,
          label: 'About TutorLink',
          onTap: () => _showAbout(context),
        ),
        _SettingsTile(
          icon: Icons.logout_rounded,
          label: 'Logout',
          color: AppColors.error,
          onTap: () => _logout(context),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'TutorLink',
      applicationVersion: '1.0.0',
      applicationLegalese: 'Parent ↔ Teacher ↔ Child Collaboration App',
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await _showLogoutDialog(context);
    if (confirm == true) {
      await _auth.logout();
      if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }
}

//  Teacher Profile

class _TeacherProfile extends StatelessWidget {
  final AppUser user;
  final _fs = FirestoreService();
  final _auth = AuthService();

  _TeacherProfile({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _ProfileHeader(user: user),
            const Divider(),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const SectionHeader(title: 'My Students'),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<TeacherChildLink>>(
              stream: _fs.teacherLinksStream(user.uid),
              builder: (context, snap) {
                final links = snap.data ?? [];
                if (links.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: const EmptyState(
                      icon: Icons.people_alt_rounded,
                      title: 'No students yet',
                      subtitle: 'Parents will link you to their children.',
                    ),
                  );
                }
                return Column(
                  children: links
                      .map(
                        (l) => ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          leading: RectAvatar(
                            imagePath: l.childAvatarUrl.isNotEmpty
                                ? l.childAvatarUrl
                                : null,
                            name: l.childName,
                            width: 36,
                            height: 46,
                            borderRadius: 8,
                          ),
                          title: Text(
                            l.childName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            l.subject,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textHint,
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudentProgressScreen(
                                childId: l.childId,
                                childName: l.childName,
                                teacherId: user.uid,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const Divider(),
            _buildSettings(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSettings(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        _SettingsTile(
          icon: Icons.notifications_outlined,
          label: 'Notifications',
          onTap: () {},
        ),
        _SettingsTile(
          icon: Icons.info_outline_rounded,
          label: 'About TutorLink',
          onTap: () => showAboutDialog(
            context: context,
            applicationName: 'TutorLink',
            applicationVersion: '1.0.0',
          ),
        ),
        _SettingsTile(
          icon: Icons.logout_rounded,
          label: 'Logout',
          color: AppColors.error,
          onTap: () async {
            final confirm = await _showLogoutDialog(context);
            if (confirm == true) {
              await _auth.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            }
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

//  Child Profile

class _ChildProfile extends StatelessWidget {
  final AppUser user;
  final _fs = FirestoreService();
  final _auth = AuthService();

  _ChildProfile({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _ProfileHeader(user: user),
            const Divider(),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SectionHeader(title: 'My Teachers'),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<TeacherChildLink>>(
              stream: _fs.childLinksStream(user.uid),
              builder: (context, snap) {
                final links = snap.data ?? [];
                if (links.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: EmptyState(
                      icon: Icons.auto_stories_rounded,
                      title: 'No teachers yet',
                      subtitle: 'Your teachers will appear here once linked.',
                    ),
                  );
                }
                return Column(
                  children: links
                      .map(
                        (l) => ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          leading: RectAvatar(
                            imagePath: l.teacherAvatarUrl.isNotEmpty
                                ? l.teacherAvatarUrl
                                : null,
                            name: l.teacherName,
                            width: 36,
                            height: 46,
                            borderRadius: 8,
                          ),
                          title: Text(
                            l.teacherName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            l.subject,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const Divider(),
            Column(
              children: [
                const SizedBox(height: 8),
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  color: AppColors.error,
                  onTap: () async {
                    final confirm = await _showLogoutDialog(context);
                    if (confirm == true) {
                      await _auth.logout();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    }
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

//  Shared Widgets

class _ChildListTile extends StatelessWidget {
  final Child child;
  const _ChildListTile({required this.child});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: RectAvatar(
        imagePath: child.avatarUrl,
        name: child.name,
        width: 36,
        height: 46,
        borderRadius: 8,
      ),
      title: Text(
        child.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${child.teacherIds.length} teacher${child.teacherIds.length == 1 ? '' : 's'}',
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textHint,
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              StudentProgressScreen(childId: child.id, childName: child.name),
        ),
      ),
    );
  }
}

//  Parent Add Link Sheet

class _ParentAddLinkSheet extends StatefulWidget {
  final AppUser parent;
  const _ParentAddLinkSheet({required this.parent});

  @override
  State<_ParentAddLinkSheet> createState() => _ParentAddLinkSheetState();
}

class _ParentAddLinkSheetState extends State<_ParentAddLinkSheet> {
  final _teacherEmailCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final List<TextEditingController> _childEmailCtrls = [
    TextEditingController(),
  ];
  final _fs = FirestoreService();
  bool _loading = false;
  String? _globalError;
  final List<String?> _childErrors = [null];

  @override
  void dispose() {
    _teacherEmailCtrl.dispose();
    _subjectCtrl.dispose();
    for (final c in _childEmailCtrls) c.dispose();
    super.dispose();
  }

  void _addChildField() {
    setState(() {
      _childEmailCtrls.add(TextEditingController());
      _childErrors.add(null);
    });
  }

  void _removeChildField(int index) {
    if (_childEmailCtrls.length == 1) return;
    setState(() {
      _childEmailCtrls[index].dispose();
      _childEmailCtrls.removeAt(index);
      _childErrors.removeAt(index);
    });
  }

  Future<void> _submit() async {
    final teacherEmail = _teacherEmailCtrl.text.trim();
    final subject = _subjectCtrl.text.trim();

    if (teacherEmail.isEmpty || subject.isEmpty) {
      setState(
        () => _globalError = 'Please fill in teacher email and subject.',
      );
      return;
    }

    final childEmails = _childEmailCtrls.map((c) => c.text.trim()).toList();
    if (childEmails.any((e) => e.isEmpty)) {
      setState(() => _globalError = 'Please fill in all student email fields.');
      return;
    }

    setState(() {
      _loading = true;
      _globalError = null;
    });

    bool anyError = false;
    final newChildErrors = List<String?>.filled(_childEmailCtrls.length, null);

    for (int i = 0; i < childEmails.length; i++) {
      final result = await _fs.parentCreateLink(
        parentId: widget.parent.uid,
        teacherEmail: teacherEmail,
        subject: subject,
        childEmail: childEmails[i],
      );
      if (result['success'] != true) {
        newChildErrors[i] = result['error'];
        anyError = true;
      }
    }

    if (mounted)
      setState(() {
        _childErrors.setAll(0, newChildErrors);
        _loading = false;
      });

    if (!anyError && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Links created successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Link Teacher & Student',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'All emails must belong to registered TutorLink accounts.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _teacherEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Teacher's Email",
                prefixIcon: Icon(Icons.auto_stories_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _subjectCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Subject (e.g. Mathematics)',
                prefixIcon: Icon(Icons.menu_book_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text(
                  "Student's Email(s)",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addChildField,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text(
                    'Add another',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(
              _childEmailCtrls.length,
              (i) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _childEmailCtrls[i],
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText:
                                'Student ${_childEmailCtrls.length > 1 ? i + 1 : ""}Email',
                            prefixIcon: const Icon(
                              Icons.child_care_rounded,
                              size: 20,
                            ),
                            errorText: _childErrors.length > i
                                ? _childErrors[i]
                                : null,
                          ),
                        ),
                      ),
                      if (_childEmailCtrls.length > 1) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _removeChildField(i),
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            if (_globalError != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _globalError!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Create Links'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//  Settings Tile

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: c, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: c),
      ),
      trailing: color == null
          ? const Icon(Icons.chevron_right_rounded, color: AppColors.textHint)
          : null,
      onTap: onTap,
    );
  }
}

//  Logout Dialog (shared)

Future<bool?> _showLogoutDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      actionsPadding: const EdgeInsets.all(16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: AppColors.error,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Logout',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Are you sure you want to logout?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Colors.black),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
