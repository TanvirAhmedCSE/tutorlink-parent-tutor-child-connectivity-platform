import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';
import '../../widgets/widgets.dart';

class StudentProgressScreen extends StatefulWidget {
  final String childId;
  final String childName;
  final String? teacherId;

  const StudentProgressScreen({
    super.key,
    required this.childId,
    required this.childName,
    this.teacherId,
  });

  @override
  State<StudentProgressScreen> createState() => _StudentProgressScreenState();
}

class _StudentProgressScreenState extends State<StudentProgressScreen> {
  final _fs = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(widget.childName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Teacher can update progress from here
          if (widget.teacherId != null)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => _showUpdateProgressSheet(context),
              tooltip: 'Update Progress',
            ),
        ],
      ),
      body: StreamBuilder<List<ProgressUpdate>>(
        stream: _fs.childProgressStream(widget.childId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const AppLoading();
          }
          List<ProgressUpdate> allProgress = snap.data ?? [];

          // If teacherId provided, filter to only that teacher's records
          final progress = widget.teacherId != null
              ? allProgress
                    .where((p) => p.teacherId == widget.teacherId)
                    .toList()
              : allProgress;

          if (progress.isEmpty) {
            return EmptyState(
              icon: Icons.bar_chart_rounded,
              title: 'No progress yet',
              subtitle: widget.teacherId != null
                  ? 'Tap the edit button to add progress.'
                  : 'Teachers will update progress here.',
              action: widget.teacherId != null
                  ? ElevatedButton(
                      onPressed: () => _showUpdateProgressSheet(context),
                      child: const Text('Add Progress'),
                    )
                  : null,
            );
          }

          final overall =
              progress.fold(0.0, (s, p) => s + p.overall) / progress.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverallCard(overall, progress.length),
                const SizedBox(height: 24),
                const Text(
                  'Subject Breakdown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...progress.map(
                  (p) => _SubjectProgressCard(
                    progress: p,
                    showTeacher: widget.teacherId == null,
                  ),
                ),
                if (progress.any(
                  (p) => p.notes != null && p.notes!.isNotEmpty,
                )) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Teacher Notes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...progress
                      .where((p) => p.notes != null && p.notes!.isNotEmpty)
                      .map((p) => _NoteCard(progress: p)),
                ],
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverallCard(double overall, int subjectCount) {
    Color progressColor;
    String progressLabel;
    if (overall >= 80) {
      progressColor = AppColors.success;
      progressLabel = 'Excellent';
    } else if (overall >= 60) {
      progressColor = AppColors.warning;
      progressLabel = 'Good';
    } else {
      progressColor = AppColors.error;
      progressLabel = 'Needs Attention';
    }

    return Container(
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
                Text(
                  widget.childName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$subjectCount subject${subjectCount == 1 ? '' : 's'} tracked',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    progressLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ProgressRing(
            percent: overall,
            radius: 50,
            color: Colors.white,
            showText: true,
          ),
        ],
      ),
    );
  }

  void _showUpdateProgressSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UpdateProgressSheet(
        childId: widget.childId,
        childName: widget.childName,
        teacherId: widget.teacherId!,
      ),
    );
  }
}

//  Subject Progress Card
class _SubjectProgressCard extends StatelessWidget {
  final ProgressUpdate progress;
  final bool showTeacher;

  const _SubjectProgressCard({
    required this.progress,
    required this.showTeacher,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      progress.subject,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (showTeacher)
                      Text(
                        progress.teacherName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              ProgressRing(
                percent: progress.overall,
                radius: 30,
                showText: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ScoreBar(
            label: 'Homework',
            value: progress.homeworkCompletion,
            color: AppColors.primary,
          ),
          const SizedBox(height: 10),
          ScoreBar(
            label: 'Understanding',
            value: progress.understanding,
            color: AppColors.info,
          ),
          const SizedBox(height: 10),
          ScoreBar(
            label: 'Participation',
            value: progress.participation,
            color: AppColors.secondary,
          ),
          const SizedBox(height: 10),
          ScoreBar(
            label: 'Improvement',
            value: progress.improvement,
            color: AppColors.accent,
          ),
          const SizedBox(height: 8),
          Text(
            'Updated ${DateFormat('MMM d, y').format(progress.updatedAt)}',
            style: const TextStyle(fontSize: 11, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

//  Note Card
class _NoteCard extends StatelessWidget {
  final ProgressUpdate progress;
  const _NoteCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
          const SizedBox(height: 8),
          Text(
            progress.notes!,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

//  Update Progress Sheet
class _UpdateProgressSheet extends StatefulWidget {
  final String childId;
  final String childName;
  final String teacherId;

  const _UpdateProgressSheet({
    required this.childId,
    required this.childName,
    required this.teacherId,
  });

  @override
  State<_UpdateProgressSheet> createState() => _UpdateProgressSheetState();
}

class _UpdateProgressSheetState extends State<_UpdateProgressSheet> {
  final _fs = FirestoreService();
  final _subjectCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  int _homework = 70;
  int _understanding = 70;
  int _participation = 70;
  int _improvement = 70;
  bool _loading = false;
  String? _teacherName;

  @override
  void initState() {
    super.initState();
    _loadTeacherName();
  }

  Future<void> _loadTeacherName() async {
    final user = await _fs.getUser(widget.teacherId);
    if (mounted && user != null) {
      setState(() => _teacherName = user.name);
    }
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_subjectCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a subject name')));
      return;
    }
    setState(() => _loading = true);
    try {
      await _fs.upsertProgress(
        teacherId: widget.teacherId,
        teacherName: _teacherName ?? 'Teacher',
        childId: widget.childId,
        subject: _subjectCtrl.text.trim(),
        homework: _homework,
        understanding: _understanding,
        participation: _participation,
        improvement: _improvement,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Progress updated!')));
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
      // padding: EdgeInsets.fromLTRB(
      //     24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
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
            Text(
              'Update Progress — ${widget.childName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _subjectCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Subject (e.g. Math)',
              ),
            ),
            const SizedBox(height: 20),
            _ScoreSlider(
              label: 'Homework Completion',
              value: _homework,
              color: AppColors.primary,
              onChanged: (v) => setState(() => _homework = v),
            ),
            const SizedBox(height: 16),
            _ScoreSlider(
              label: 'Understanding',
              value: _understanding,
              color: AppColors.info,
              onChanged: (v) => setState(() => _understanding = v),
            ),
            const SizedBox(height: 16),
            _ScoreSlider(
              label: 'Participation',
              value: _participation,
              color: AppColors.secondary,
              onChanged: (v) => setState(() => _participation = v),
            ),
            const SizedBox(height: 16),
            _ScoreSlider(
              label: 'Improvement',
              value: _improvement,
              color: AppColors.accent,
              onChanged: (v) => setState(() => _improvement = v),
            ),
            const SizedBox(height: 16),
            // Overall preview
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryFaint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text(
                    'Overall Score',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${((_homework + _understanding + _participation + _improvement) / 4).round()}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes / Feedback (optional)',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Save Progress'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreSlider extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final ValueChanged<int> onChanged;

  const _ScoreSlider({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$value',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: AppColors.divider,
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.1),
            trackHeight: 4,
          ),
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 100,
            divisions: 20,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
      ],
    );
  }
}
