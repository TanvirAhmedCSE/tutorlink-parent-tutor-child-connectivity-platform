import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';
import '../../widgets/widgets.dart';
import '../../utils/constants.dart';
import '../../widgets/attachment_widgets.dart';
import '../../services/cloudinary_service.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final Assignment assignment;
  final AppUser currentUser;

  const AssignmentDetailScreen({
    super.key,
    required this.assignment,
    required this.currentUser,
  });

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  final _fs = FirestoreService();
  Submission? _submission;
  bool _loadingSubmission = true;
  late AssignmentStatus _localStatus;

  @override
  void initState() {
    super.initState();
    _localStatus = widget.assignment.status;
    _loadSubmission();
  }

  Future<void> _loadSubmission() async {
    final sub = await _fs.getSubmission(widget.assignment.id);
    if (mounted) {
      setState(() {
        _submission = sub;
        _loadingSubmission = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignment = widget.assignment;
    final isTeacher = widget.currentUser.role == UserRole.teacher;
    final isChild = widget.currentUser.role == UserRole.child;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Assignment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loadingSubmission
          ? const AppLoading()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(assignment),
                  const SizedBox(height: 20),
                  _buildInfoCard(assignment),
                  const SizedBox(height: 16),
                  _buildInstructions(assignment),
                  const SizedBox(height: 16),
                  if (_submission != null) ...[
                    _buildSubmissionCard(_submission!),
                    const SizedBox(height: 16),
                  ],
                  if (isTeacher &&
                      _localStatus == AssignmentStatus.submitted &&
                      _submission != null)
                    _buildReviewButton(context),
                  if (isChild && _localStatus == AssignmentStatus.pending)
                    _buildSubmitButton(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(Assignment assignment) {
    Color statusColor;
    String statusLabel;
    switch (_localStatus) {
      case AssignmentStatus.pending:
        statusColor = AppColors.warning;
        statusLabel = 'Pending';
        break;
      case AssignmentStatus.submitted:
        statusColor = AppColors.info;
        statusLabel = 'Submitted';
        break;
      case AssignmentStatus.reviewed:
        statusColor = AppColors.success;
        statusLabel = 'Reviewed';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                assignment.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            StatusBadge(label: statusLabel, color: statusColor),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${assignment.subject} • ${assignment.teacherName}',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildInfoCard(Assignment assignment) {
    final isOverdue =
        _localStatus == AssignmentStatus.pending &&
        assignment.dueDate.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Student',
            value: assignment.childName,
          ),
          const Divider(height: 20),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Due Date',
            value: DateFormat('EEEE, MMM d, y').format(assignment.dueDate),
            valueColor: isOverdue ? AppColors.error : null,
          ),
          const Divider(height: 20),
          _InfoRow(
            icon: Icons.access_time_rounded,
            label: 'Created',
            value: DateFormat('MMM d, y').format(assignment.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions(Assignment assignment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Instructions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Text(
            assignment.instructions,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.6,
            ),
          ),
        ),

        if (assignment.attachments.isNotEmpty) ...[
          const SizedBox(height: 10),
          AttachmentViewSection(attachments: assignment.attachments),
        ],
      ],
    );
  }

  Widget _buildSubmissionCard(Submission submission) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Submission',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.success,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Submitted ${DateFormat('MMM d, y').format(submission.submittedAt)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (submission.comment != null &&
                  submission.comment!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  submission.comment!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
              if (submission.attachments.isNotEmpty) ...[
                const SizedBox(height: 12),
                AttachmentViewSection(attachments: submission.attachments),
              ],
              if (submission.reviewStatus != null) ...[
                const Divider(height: 24),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: submission.reviewStatus == ReviewStatus.approved
                        ? AppColors.success.withValues(alpha: 0.08)
                        : AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: submission.reviewStatus == ReviewStatus.approved
                          ? AppColors.success.withValues(alpha: 0.3)
                          : AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            submission.reviewStatus == ReviewStatus.approved
                                ? Icons.check_circle_rounded
                                : Icons.warning_amber_rounded,
                            color:
                                submission.reviewStatus == ReviewStatus.approved
                                ? AppColors.success
                                : AppColors.warning,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            submission.reviewStatus == ReviewStatus.approved
                                ? 'Approved'
                                : 'Needs Improvement',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color:
                                  submission.reviewStatus ==
                                      ReviewStatus.approved
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                          if (submission.marks != null) ...[
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${submission.marks} marks',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (submission.teacherFeedback != null &&
                          submission.teacherFeedback!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          submission.teacherFeedback!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showSubmitSheet(context),
        icon: const Icon(Icons.upload_rounded),
        label: const Text('Submit Assignment'),
      ),
    );
  }

  Widget _buildReviewButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showReviewSheet(context),
        icon: const Icon(Icons.rate_review_outlined),
        label: const Text('Review Submission'),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
      ),
    );
  }

  void _showSubmitSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubmitSheet(
        assignment: widget.assignment,
        child: widget.currentUser,
        onSubmitted: () {
          _loadSubmission();
          Navigator.pop(context);
          setState(() => _localStatus = AssignmentStatus.submitted);
        },
      ),
    );
  }

  void _showReviewSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReviewSheet(
        assignment: widget.assignment,
        submission: _submission!,
        onReviewed: () {
          _loadSubmission();
          Navigator.pop(context);
          setState(() => _localStatus = AssignmentStatus.reviewed);
        },
      ),
    );
  }
}

//  Info Row
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

//  Submit Sheet
class _SubmitSheet extends StatefulWidget {
  final Assignment assignment;
  final AppUser child;
  final VoidCallback onSubmitted;

  const _SubmitSheet({
    required this.assignment,
    required this.child,
    required this.onSubmitted,
  });

  @override
  State<_SubmitSheet> createState() => _SubmitSheetState();
}

class _SubmitSheetState extends State<_SubmitSheet> {
  final _commentCtrl = TextEditingController();
  final _fs = FirestoreService();
  bool _loading = false;

  final List<PendingAttachment> _attachments = [];

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final hasText = _commentCtrl.text.trim().isNotEmpty;
    final hasFiles = _attachments.isNotEmpty;

    if (!hasText && !hasFiles) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Write your answer or attach a file before submitting'),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      List<AssignmentAttachment> uploaded = [];
      if (_attachments.isNotEmpty) {
        uploaded = await uploadPendingAttachments<AssignmentAttachment>(
          pending: _attachments,
          folder: CloudinaryFolder.submissionImages,
          onProgress: () {
            if (mounted) setState(() {});
          },
          builder: (url, filename, type) =>
              AssignmentAttachment(url: url, filename: filename, type: type),
        );
      }

      await _fs.createSubmission(
        assignmentId: widget.assignment.id,
        childId: widget.child.uid,
        comment: _commentCtrl.text.trim().isEmpty
            ? null
            : _commentCtrl.text.trim(),
        attachments: uploaded, // NEW
      );
      if (mounted) {
        widget.onSubmitted();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Assignment submitted!')));
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
              'Submit Assignment',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              widget.assignment.title,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _commentCtrl,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Your Answer',
                hintText: 'Write your answer here...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            // NEW: attachment picker
            AttachmentPickerSection(
              attachments: _attachments,
              onAdded: (a) => setState(() => _attachments.add(a)),
              onRemoved: (i) => setState(() => _attachments.removeAt(i)),
            ),
            const SizedBox(height: 12),
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
                    : const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//  Review Sheet
class _ReviewSheet extends StatefulWidget {
  final Assignment assignment;
  final Submission submission;
  final VoidCallback onReviewed;

  const _ReviewSheet({
    required this.assignment,
    required this.submission,
    required this.onReviewed,
  });

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  final _feedbackCtrl = TextEditingController();
  final _marksCtrl = TextEditingController();
  final _fs = FirestoreService();
  ReviewStatus _status = ReviewStatus.approved;
  bool _loading = false;

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    _marksCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_feedbackCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please add feedback')));
      return;
    }
    final marks = int.tryParse(_marksCtrl.text.trim()) ?? 0;
    setState(() => _loading = true);
    try {
      await _fs.reviewSubmission(
        submissionId: widget.submission.id,
        assignmentId: widget.assignment.id,
        status: _status,
        feedback: _feedbackCtrl.text.trim(),
        marks: marks,
      );
      if (mounted) {
        widget.onReviewed();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Review submitted!')));
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
              'Review Submission',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            if (widget.submission.comment != null &&
                widget.submission.comment!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Student\'s Answer',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.submission.comment!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Text(
              'Status',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _StatusOption(
                    label: 'Approved',
                    selected: _status == ReviewStatus.approved,
                    color: AppColors.success,
                    onTap: () =>
                        setState(() => _status = ReviewStatus.approved),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatusOption(
                    label: 'Needs Work',
                    selected: _status == ReviewStatus.needsImprovement,
                    color: AppColors.warning,
                    onTap: () =>
                        setState(() => _status = ReviewStatus.needsImprovement),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _feedbackCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Feedback',
                hintText: 'Write your feedback here...',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _marksCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Marks (optional)',
                hintText: 'e.g. 85',
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
                    : const Text('Submit Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _StatusOption({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? color : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
