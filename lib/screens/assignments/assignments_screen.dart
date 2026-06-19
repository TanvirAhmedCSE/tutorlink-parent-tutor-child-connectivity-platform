import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';
import '../../widgets/widgets.dart';
import 'assignment_detail_screen.dart';
import '../../utils/constants.dart';
import '../../widgets/attachment_widgets.dart';
import '../../services/cloudinary_service.dart';

class AssignmentsScreen extends StatelessWidget {
  final AppUser user;

  const AssignmentsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    switch (user.role) {
      case UserRole.teacher:
        return _TeacherAssignments(user: user);
      case UserRole.child:
        return _ChildAssignments(user: user);
      case UserRole.parent:
        return _ParentAssignments(user: user);
    }
  }
}

// Teacher Assignments
class _TeacherAssignments extends StatefulWidget {
  final AppUser user;
  const _TeacherAssignments({required this.user});

  @override
  State<_TeacherAssignments> createState() => _TeacherAssignmentsState();
}

class _TeacherAssignmentsState extends State<_TeacherAssignments>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _fs = FirestoreService();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Assignments'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: AppColors.divider,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Submitted'),
            Tab(text: 'Reviewed'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Assignment'),
      ),
      body: StreamBuilder<List<Assignment>>(
        stream: _fs.teacherAssignmentsStream(widget.user.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const AppLoading();
          }
          final all = snap.data ?? [];
          final submitted = all
              .where((a) => a.status == AssignmentStatus.submitted)
              .toList();
          final reviewed = all
              .where((a) => a.status == AssignmentStatus.reviewed)
              .toList();

          return TabBarView(
            controller: _tabCtrl,
            children: [
              _AssignmentList(
                assignments: all,
                currentUser: widget.user,
                emptyTitle: 'No assignments yet',
                emptySubtitle: 'Create your first assignment.',
              ),
              _AssignmentList(
                assignments: submitted,
                currentUser: widget.user,
                emptyTitle: 'Nothing submitted',
                emptySubtitle: 'Students haven\'t submitted yet.',
              ),
              _AssignmentList(
                assignments: reviewed,
                currentUser: widget.user,
                emptyTitle: 'Nothing reviewed',
                emptySubtitle: 'No reviewed assignments yet.',
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateAssignmentSheet(teacher: widget.user),
    );
  }
}

// Child Assignments
class _ChildAssignments extends StatefulWidget {
  final AppUser user;
  const _ChildAssignments({required this.user});

  @override
  State<_ChildAssignments> createState() => _ChildAssignmentsState();
}

class _ChildAssignmentsState extends State<_ChildAssignments>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _fs = FirestoreService();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('My Assignments'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
          dividerColor: AppColors.divider,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Submitted'),
            Tab(text: 'Reviewed'),
          ],
        ),
      ),
      body: StreamBuilder<List<Assignment>>(
        stream: _fs.childAssignmentsStream(widget.user.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const AppLoading();
          }
          final all = snap.data ?? [];
          final pending = all
              .where((a) => a.status == AssignmentStatus.pending)
              .toList();
          final submitted = all
              .where((a) => a.status == AssignmentStatus.submitted)
              .toList();
          final reviewed = all
              .where((a) => a.status == AssignmentStatus.reviewed)
              .toList();

          return TabBarView(
            controller: _tabCtrl,
            children: [
              _AssignmentList(
                assignments: pending,
                currentUser: widget.user,
                emptyTitle: 'No pending assignments',
                emptySubtitle: 'You\'re all caught up!',
              ),
              _AssignmentList(
                assignments: submitted,
                currentUser: widget.user,
                emptyTitle: 'Nothing submitted',
                emptySubtitle: 'Submit your pending assignments.',
              ),
              _AssignmentList(
                assignments: reviewed,
                currentUser: widget.user,
                emptyTitle: 'Nothing reviewed yet',
                emptySubtitle: 'Your teacher hasn\'t reviewed submissions yet.',
              ),
            ],
          );
        },
      ),
    );
  }
}

//  Parent Assignments
class _ParentAssignments extends StatefulWidget {
  final AppUser user;
  const _ParentAssignments({required this.user});

  @override
  State<_ParentAssignments> createState() => _ParentAssignmentsState();
}

class _ParentAssignmentsState extends State<_ParentAssignments> {
  final _fs = FirestoreService();
  String _selectedChildId = 'all';
  String _selectedStatus = 'all';

  List<Assignment> _applyFilters(List<Assignment> assignments) {
    return assignments.where((a) {
      final childMatch =
          _selectedChildId == 'all' || a.childId == _selectedChildId;
      final statusMatch =
          _selectedStatus == 'all' ||
          (_selectedStatus == 'pending' &&
              a.status == AssignmentStatus.pending) ||
          (_selectedStatus == 'submitted' &&
              a.status == AssignmentStatus.submitted) ||
          (_selectedStatus == 'reviewed' &&
              a.status == AssignmentStatus.reviewed);
      return childMatch && statusMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Children\'s Assignments'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<Child>>(
        stream: _fs.parentChildrenStream(widget.user.uid),
        builder: (context, childSnap) {
          final children = childSnap.data ?? [];
          if (children.isEmpty) {
            return const EmptyState(
              icon: Icons.assignment_outlined,
              title: 'No children linked',
              subtitle: 'Your children\'s assignments will appear here.',
            );
          }
          final childIds = children.map((c) => c.id).toList();

          return StreamBuilder<List<Assignment>>(
            stream: _fs.childrenAssignmentsStream(childIds),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const AppLoading();
              }
              final allAssignments = snap.data ?? [];
              final filtered = _applyFilters(allAssignments);

              return Column(
                children: [
                  _buildChildChips(children),
                  _buildStatusChips(),
                  Expanded(
                    child: filtered.isEmpty
                        ? const EmptyState(
                            icon: Icons.assignment_outlined,
                            title: 'No assignments',
                            subtitle:
                                'No assignments match the selected filters.',
                          )
                        : _AssignmentList(
                            assignments: filtered,
                            currentUser: widget.user,
                            emptyTitle: 'No assignments',
                            emptySubtitle: '',
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildChildChips(List<Child> children) {
    return SizedBox(
      height: 44,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: 'All',
            selected: _selectedChildId == 'all',
            onTap: () => setState(() => _selectedChildId = 'all'),
          ),
          ...children.map(
            (c) => _FilterChip(
              label: c.name,
              selected: _selectedChildId == c.id,
              onTap: () => setState(() => _selectedChildId = c.id),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChips() {
    const statuses = [
      ('all', 'All', null),
      ('pending', 'Pending', AppColors.warning),
      ('submitted', 'Submitted', AppColors.info),
      ('reviewed', 'Reviewed', AppColors.success),
    ];

    return SizedBox(
      height: 44,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        scrollDirection: Axis.horizontal,
        children: statuses
            .map(
              (s) => _FilterChip(
                label: s.$2,
                selected: _selectedStatus == s.$1,
                onTap: () => setState(() => _selectedStatus = s.$1),
                color: s.$3,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: 0.12) : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c : AppColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? c : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// Shared Assignment List
class _AssignmentList extends StatelessWidget {
  final List<Assignment> assignments;
  final AppUser currentUser;
  final String emptyTitle;
  final String emptySubtitle;

  const _AssignmentList({
    required this.assignments,
    required this.currentUser,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    if (assignments.isEmpty) {
      return EmptyState(
        icon: Icons.assignment_outlined,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: assignments.length,
      itemBuilder: (context, i) =>
          _AssignmentCard(assignment: assignments[i], currentUser: currentUser),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final AppUser currentUser;

  const _AssignmentCard({required this.assignment, required this.currentUser});

  Color get _statusColor {
    switch (assignment.status) {
      case AssignmentStatus.pending:
        return AppColors.warning;
      case AssignmentStatus.submitted:
        return AppColors.info;
      case AssignmentStatus.reviewed:
        return AppColors.success;
    }
  }

  String get _statusLabel {
    switch (assignment.status) {
      case AssignmentStatus.pending:
        return 'Pending';
      case AssignmentStatus.submitted:
        return 'Submitted';
      case AssignmentStatus.reviewed:
        return 'Reviewed';
    }
  }

  bool get _isOverdue =>
      assignment.status == AssignmentStatus.pending &&
      assignment.dueDate.isBefore(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AssignmentDetailScreen(
            assignment: assignment,
            currentUser: currentUser,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isOverdue
                ? AppColors.error
                : assignment.status == AssignmentStatus.submitted
                ? AppColors.info
                : assignment.status == AssignmentStatus.reviewed
                ? AppColors.success
                : Colors.orange.withValues(alpha: 0.7),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    assignment.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                StatusBadge(label: _statusLabel, color: _statusColor),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${assignment.subject} • ${assignment.teacherName}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            if (currentUser.role == UserRole.parent ||
                currentUser.role == UserRole.teacher)
              Text(
                'Student: ${assignment.childName}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: _isOverdue ? AppColors.error : AppColors.textHint,
                ),
                const SizedBox(width: 4),
                Text(
                  'Due: ${DateFormat('MMM d, y').format(assignment.dueDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isOverdue ? AppColors.error : AppColors.textHint,
                    fontWeight: _isOverdue ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Create Assignment Sheet
class _CreateAssignmentSheet extends StatefulWidget {
  final AppUser teacher;
  const _CreateAssignmentSheet({required this.teacher});

  @override
  State<_CreateAssignmentSheet> createState() => _CreateAssignmentSheetState();
}

class _CreateAssignmentSheetState extends State<_CreateAssignmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  final _fs = FirestoreService();

  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  List<TeacherChildLink> _selectedLinks = [];
  List<TeacherChildLink> _links = [];
  bool _loading = false;

  final List<PendingAttachment> _attachments = [];

  @override
  void initState() {
    super.initState();
    _fs.teacherLinksStream(widget.teacher.uid).listen((links) {
      if (mounted) setState(() => _links = links);
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _showStudentPickerDialog() async {
    // local state for the dialog
    List<TeacherChildLink> tempSelected = List.from(_selectedLinks);

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final allSelected = tempSelected.length == _links.length;

            return AlertDialog(
              backgroundColor: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Select Students',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Select All / Deselect All
                    InkWell(
                      onTap: () {
                        setDialogState(() {
                          if (allSelected) {
                            tempSelected.clear();
                          } else {
                            tempSelected = List.from(_links);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: allSelected
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: allSelected
                                ? AppColors.primary.withValues(alpha: 0.3)
                                : AppColors.divider,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              allSelected
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              color: allSelected
                                  ? AppColors.primary
                                  : AppColors.textHint,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              allSelected ? 'Deselect All' : 'Select All',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: allSelected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${tempSelected.length}/${_links.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textHint,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 4),
                    // Student List
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(ctx).size.height * 0.35,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _links.length,
                        itemBuilder: (_, i) {
                          final link = _links[i];
                          final isSelected = tempSelected.any(
                            (l) => l.id == link.id,
                          );
                          return InkWell(
                            onTap: () {
                              setDialogState(() {
                                if (isSelected) {
                                  tempSelected.removeWhere(
                                    (l) => l.id == link.id,
                                  );
                                } else {
                                  tempSelected.add(link);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 4,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.check_box_rounded
                                        : Icons.check_box_outline_blank_rounded,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textHint,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  AppAvatar(name: link.childName, radius: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          link.childName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          link.subject,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: tempSelected.isEmpty
                      ? null
                      : () {
                          setState(() => _selectedLinks = tempSelected);
                          Navigator.pop(ctx);
                        },
                  child: Text('Done (${tempSelected.length})'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLinks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one student')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      // Upload attachments first
      List<AssignmentAttachment> uploaded = [];
      if (_attachments.isNotEmpty) {
        uploaded = await uploadPendingAttachments<AssignmentAttachment>(
          pending: _attachments,
          folder: CloudinaryFolder.assignmentImages,
          onProgress: () {
            if (mounted) setState(() {});
          },
          builder: (url, filename, type) =>
              AssignmentAttachment(url: url, filename: filename, type: type),
        );
      }

      for (final link in _selectedLinks) {
        await _fs.createAssignment(
          teacherId: widget.teacher.uid,
          teacherName: widget.teacher.name,
          childId: link.childId,
          childName: link.childName,
          subject: link.subject,
          title: _titleCtrl.text.trim(),
          instructions: _instructionsCtrl.text.trim(),
          dueDate: _dueDate,
          attachments: uploaded,
        );
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedLinks.length == 1
                  ? 'Assignment created!'
                  : 'Assignment created for ${_selectedLinks.length} students!',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
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
        child: Form(
          key: _formKey,
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
                'New Assignment',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),
              // Student Picker Button
              const Text(
                'Students',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _links.isEmpty ? null : _showStudentPickerDialog,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.card,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.people_alt_outlined,
                        size: 18,
                        color: _selectedLinks.isEmpty
                            ? AppColors.textHint
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _selectedLinks.isEmpty
                            ? Text(
                                _links.isEmpty
                                    ? 'No students linked yet'
                                    : 'Tap to select students',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textHint,
                                ),
                              )
                            : Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: _selectedLinks
                                    .map(
                                      (l) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          l.childName,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textHint,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _instructionsCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Instructions',
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter instructions' : null,
              ),
              const SizedBox(height: 14),
              // attachment picker
              AttachmentPickerSection(
                attachments: _attachments,
                onAdded: (a) => setState(() => _attachments.add(a)),
                onRemoved: (i) => setState(() => _attachments.removeAt(i)),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _dueDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.card,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Due: ${DateFormat('MMM d, y').format(_dueDate)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textHint,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
                      : const Text('Create Assignment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
