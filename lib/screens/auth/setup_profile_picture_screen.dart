import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

// color mapping for each student main image index (1-10)
const _studentColors = {
  1: Color(0xFF3A6BC4), // Kid 1 - Deep Sky Blue
  2: Color(0xFF4CAF82), // Kid 2 - Green
  3: Color(0xFF9B5DE5), // Kid 3 - Purple
  4: Color(0xFFEF6C00), // Kid 4 - Orange
  5: Color(0xFF20B2AA), // Kid 5 - Teal
  6: Color(0xFFFF69B4), // Kid 6 - Pink
  7: Color(0xFFFFD60A), // Kid 7 - Yellow
  8: Color(0xFF8A4FFF), // Kid 8 - Purple
  9: Color(0xFFFF85C1), // Kid 9 - Pink
  10: Color(0xFF20B2AA), // Kid 10 - Teal
};

class SetupProfilePictureScreen extends StatefulWidget {
  final AppUser user;
  // if true, navigates back to profile screen instead of home after done
  final bool isUpdate;
  final VoidCallback? onAvatarSaved;

  const SetupProfilePictureScreen({
    super.key,
    required this.user,
    this.isUpdate = false,
    this.onAvatarSaved,
  });

  @override
  State<SetupProfilePictureScreen> createState() =>
      _SetupProfilePictureScreenState();
}

class _SetupProfilePictureScreenState extends State<SetupProfilePictureScreen> {
  String? _selectedMainPath;
  String? _selectedSecondPath;
  Color? _selectedColor;
  bool _saving = false;
  final _fs = FirestoreService();

  bool get _canDone => _selectedMainPath != null;

  Future<void> _showPicker() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AvatarPickerSheet(
        role: widget.user.role,
        onSelected: (mainPath, secondPath, color) {
          setState(() {
            _selectedMainPath = mainPath;
            _selectedSecondPath = secondPath;
            _selectedColor = color;
          });
        },
      ),
    );
  }

  Future<void> _done() async {
    if (!_canDone) return;
    setState(() => _saving = true);
    try {
      await _fs.updateUserAvatar(
        uid: widget.user.uid,
        avatarUrl: _selectedMainPath!,
        secondAvatarUrl: _selectedSecondPath,
        avatarColor: _selectedColor?.value,
        role: widget.user.role,
      );
      if (!mounted) return;
      if (widget.isUpdate) {
        Navigator.pop(context);
      } else {
        widget.onAvatarSaved?.call();
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // preview
              Container(
                width: 110,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.primaryFaint,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                clipBehavior: Clip.antiAlias,
                child: _selectedMainPath != null
                    ? Image.asset(
                        _selectedMainPath!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _defaultRectAvatar(widget.user.name),
                      )
                    : _defaultRectAvatar(widget.user.name),
              ),
              const SizedBox(height: 28),
              Text(
                'Set your profile picture',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose an avatar that represents you.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showPicker,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Set Profile Picture'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canDone && !_saving ? _done : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _defaultRectAvatar(String name) {
  return Container(
    color: AppColors.primaryFaint,
    child: Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 40,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

//  Avatar Picker Bottom Sheet

class _AvatarPickerSheet extends StatefulWidget {
  final UserRole role;
  final void Function(String mainPath, String? secondPath, Color? color)
  onSelected;

  const _AvatarPickerSheet({required this.role, required this.onSelected});

  @override
  State<_AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<_AvatarPickerSheet> {
  int? _selectedIndex;

  List<String> get _mainPaths {
    switch (widget.role) {
      case UserRole.teacher:
        return List.generate(
          10,
          (i) => 'assets/images/teachers/teacher_image_${i + 1}.png',
        );
      case UserRole.parent:
        return List.generate(
          10,
          (i) => 'assets/images/parents/parent_image_${i + 1}.png',
        );
      case UserRole.child:
        return List.generate(
          10,
          (i) =>
              'assets/images/students/main_images/student_main_image_${i + 1}.png',
        );
    }
  }

  String? _secondPath(int index) {
    if (widget.role != UserRole.child) return null;
    return 'assets/images/students/second_images/student_second_image_$index.png';
  }

  Color? _colorFor(int index) {
    if (widget.role != UserRole.child) return null;
    return _studentColors[index];
  }

  void _confirm() {
    if (_selectedIndex == null) return;
    final i = _selectedIndex!;
    widget.onSelected(_mainPaths[i - 1], _secondPath(i), _colorFor(i));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose Avatar',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: 10,
            itemBuilder: (context, i) {
              final index = i + 1;
              final path = _mainPaths[i];
              final selected = _selectedIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.divider,
                      width: selected ? 2.5 : 1,
                    ),
                    color: selected
                        ? AppColors.primaryFaint
                        : AppColors.surface,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        path,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _defaultRectAvatar('?'),
                      ),
                      if (selected)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedIndex != null ? _confirm : null,
              child: const Text('Select'),
            ),
          ),
        ],
      ),
    );
  }
}

//  Reusable Rectangle Avatar Widget

class RectAvatar extends StatelessWidget {
  final String? imagePath;
  final String name;
  final double width;
  final double height;
  final double borderRadius;

  const RectAvatar({
    super.key,
    this.imagePath,
    required this.name,
    this.width = 44,
    this.height = 56,
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.primaryFaint,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: imagePath != null && imagePath!.isNotEmpty
          ? Image.asset(
              imagePath!,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _defaultRectAvatar(name),
            )
          : _defaultRectAvatar(name),
    );
  }
}
