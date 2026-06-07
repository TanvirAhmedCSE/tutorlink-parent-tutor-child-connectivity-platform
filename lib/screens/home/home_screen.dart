import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/widgets.dart';
import '../progress/student_progress_screen.dart';

class HomeScreen extends StatelessWidget {
  final AppUser user;
  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    switch (user.role) {
      case UserRole.parent:
        return _ParentHome(user: user);
      case UserRole.teacher:
        return _TeacherHome(user: user);
      case UserRole.child:
        return _ChildHome(user: user);
    }
  }
}

// Parent Home
class _ParentHome extends StatelessWidget {
  final AppUser user;
  final _fs = FirestoreService();

  _ParentHome({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(
              child: StreamBuilder<List<Child>>(
                stream: _fs.parentChildrenStream(user.uid),
                builder: (context, snap) {
                  final children = snap.data ?? [];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCards(children),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const SectionHeader(title: 'My Children'),
                      ),
                      const SizedBox(height: 12),
                      if (children.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: EmptyState(
                            icon: Icons.child_care_rounded,
                            title: 'No children yet',
                            subtitle: 'Children will appear here once linked.',
                          ),
                        )
                      else
                        ...children.map((c) => _ChildCard(child: c)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    final minute = DateTime.now().minute;
    final totalMinutes = hour * 60 + minute;

    final greeting =
        totalMinutes <
            5 *
                60 // 12:00 AM - 4:59 AM
        ? 'Good night'
        : totalMinutes <
              12 *
                  60 // 5:00 AM - 11:59 AM
        ? 'Good morning'
        : totalMinutes <
              16 *
                  60 // 12:00 PM - 3:59 PM
        ? 'Good noon'
        : totalMinutes <
              18 * 60 +
                  30 // 4:00 PM - 6:29 PM
        ? 'Good afternoon'
        : totalMinutes <
              20 *
                  60 // 6:30 PM - 7:59 PM
        ? 'Good evening'
        : 'Good night'; // 8:00 PM - 4:59 AM
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          AppAvatar(
            name: user.name,
            radius: 22,
            backgroundColor: AppColors.primaryFaint,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(List<Child> children) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.19,
        children: [
          StatCard(
            label: 'Children',
            value: '${children.length}',
            color: AppColors.parentColor,
            icon: Icons.family_restroom_rounded,
          ),
          StatCard(
            label: 'Active Teachers',
            value: children
                .fold<Set<String>>({}, (set, c) => set..addAll(c.teacherIds))
                .length
                .toString(),
            color: AppColors.teacherColor,
            icon: Icons.auto_stories_rounded,
          ),
        ],
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  final Child child;
  final _fs = FirestoreService();

  _ChildCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                StudentProgressScreen(childId: child.id, childName: child.name),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: StreamBuilder<List<ProgressUpdate>>(
            stream: _fs.childProgressStream(child.id),
            builder: (context, snap) {
              final progress = snap.data ?? [];
              final overall = progress.isEmpty
                  ? 0.0
                  : progress.fold(0.0, (s, p) => s + p.overall) /
                        progress.length;
              final pendingAssignments = 0;

              return Row(
                children: [
                  AppAvatar(name: child.name, radius: 26),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${child.teacherIds.length} teacher${child.teacherIds.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: (overall / 100).clamp(0.0, 1.0),
                          backgroundColor: AppColors.divider,
                          valueColor: AlwaysStoppedAnimation(
                            overall >= 80
                                ? AppColors.success
                                : overall >= 60
                                ? AppColors.warning
                                : AppColors.error,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          minHeight: 6,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${overall.round()}% overall',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ProgressRing(percent: overall, radius: 28, showText: true),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

//  Teacher Home
class _TeacherHome extends StatelessWidget {
  final AppUser user;
  final _fs = FirestoreService();

  _TeacherHome({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'My Dashboard',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.teacherColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Teacher',
                        style: TextStyle(
                          color: AppColors.teacherColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: StreamBuilder<List<TeacherChildLink>>(
                stream: _fs.teacherLinksStream(user.uid),
                builder: (context, snap) {
                  final links = snap.data ?? [];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                label: 'Students',
                                value: '${links.length}',
                                color: AppColors.primary,
                                icon: Icons.people_alt_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StreamBuilder<List<Assignment>>(
                                stream: _fs.teacherAssignmentsStream(user.uid),
                                builder: (ctx, as) {
                                  final pending = (as.data ?? [])
                                      .where(
                                        (a) =>
                                            a.status ==
                                            AssignmentStatus.submitted,
                                      )
                                      .length;
                                  return StatCard(
                                    label: 'Pending Reviews',
                                    value: '$pending',
                                    color: AppColors.secondary,
                                    icon: Icons.rate_review_outlined,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SectionHeader(
                          title: 'My Students',
                          action: TextButton(
                            onPressed: () {},
                            child: const Text('See all'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (links.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: EmptyState(
                            icon: Icons.people_alt_rounded,
                            title: 'No students yet',
                            subtitle:
                                'Link students to start tracking progress.',
                          ),
                        )
                      else
                        ...links.map((l) => _StudentTile(link: l)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  final TeacherChildLink link;
  final _fs = FirestoreService();

  _StudentTile({required this.link});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: AppAvatar(name: link.childName, radius: 22),
      title: Text(
        link.childName,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        link.subject,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: StreamBuilder<List<ProgressUpdate>>(
        stream: _fs.childProgressStream(link.childId),
        builder: (ctx, snap) {
          final updates = (snap.data ?? [])
              .where((p) => p.teacherId == link.teacherId)
              .toList();
          final overall = updates.isEmpty
              ? 0.0
              : updates.fold(0.0, (s, p) => s + p.overall) / updates.length;
          return ProgressRing(percent: overall, radius: 22, showText: true);
        },
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentProgressScreen(
            childId: link.childId,
            childName: link.childName,
            teacherId: link.teacherId,
          ),
        ),
      ),
    );
  }
}

//  Child Home
class _ChildHome extends StatelessWidget {
  final AppUser user;
  final _fs = FirestoreService();

  _ChildHome({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hello!',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.childColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Student',
                            style: TextStyle(
                              color: AppColors.childColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: StreamBuilder<List<ProgressUpdate>>(
                stream: _fs.childProgressStream(user.uid),
                builder: (context, snap) {
                  final progress = snap.data ?? [];
                  final overall = progress.isEmpty
                      ? 0.0
                      : progress.fold(0.0, (s, p) => s + p.overall) /
                            progress.length;
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Overall Progress',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${overall.round()}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${progress.length} subject${progress.length == 1 ? '' : 's'} tracked',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ProgressRing(
                            percent: overall,
                            radius: 44,
                            color: Colors.white,
                            showText: false,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const SectionHeader(title: 'My Subjects'),
              ),
            ),
            SliverToBoxAdapter(
              child: StreamBuilder<List<ProgressUpdate>>(
                stream: _fs.childProgressStream(user.uid),
                builder: (context, snap) {
                  final progress = snap.data ?? [];
                  if (progress.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: EmptyState(
                        icon: Icons.bar_chart_rounded,
                        title: 'No progress yet',
                        subtitle:
                            'Your teachers will update your progress here.',
                      ),
                    );
                  }
                  return Column(
                    children: progress
                        .map((p) => _SubjectProgressTile(progress: p))
                        .toList(),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: const SectionHeader(title: 'Recent Feedback'),
              ),
            ),
            SliverToBoxAdapter(
              child: StreamBuilder<List<ProgressUpdate>>(
                stream: _fs.childProgressStream(user.uid),
                builder: (context, snap) {
                  final feedback = (snap.data ?? [])
                      .where((p) => p.notes != null && p.notes!.isNotEmpty)
                      .toList();
                  if (feedback.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Text(
                        'No feedback yet.',
                        style: TextStyle(color: AppColors.textHint),
                      ),
                    );
                  }
                  return Column(
                    children: feedback
                        .take(3)
                        .map((p) => _FeedbackTile(progress: p))
                        .toList(),
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}

class _SubjectProgressTile extends StatelessWidget {
  final ProgressUpdate progress;
  const _SubjectProgressTile({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    progress.subject,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    progress.teacherName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (progress.overall / 100).clamp(0.0, 1.0),
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation(
                      progress.overall >= 80
                          ? AppColors.success
                          : progress.overall >= 60
                          ? AppColors.warning
                          : AppColors.error,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '${progress.overall.round()}%',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: progress.overall >= 80
                    ? AppColors.success
                    : progress.overall >= 60
                    ? AppColors.warning
                    : AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackTile extends StatelessWidget {
  final ProgressUpdate progress;
  const _FeedbackTile({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.accentFaint,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.format_quote_rounded,
                  color: AppColors.accent,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '${progress.teacherName} • ${progress.subject}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              progress.notes!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
