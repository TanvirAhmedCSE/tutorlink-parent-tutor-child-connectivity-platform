import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'TutorLink';

  // Hive boxes
  static const String userBox = 'user_box';
  static const String chatsBox = 'chats_box';
  static const String assignmentsBox = 'assignments_box';
  static const String notificationsBox = 'notifications_box';

  // Hive keys
  static const String currentUserKey = 'current_user';
  static const String cachedChatsKey = 'cached_chats';
  static const String cachedAssignmentsKey = 'cached_assignments';

  // Firestore collections
  static const String usersCol = 'users';
  static const String childrenCol = 'children';
  static const String linksCol = 'teacher_child_links';
  static const String groupChatsCol = 'group_chats';
  static const String messagesCol = 'messages';
  static const String assignmentsCol = 'assignments';
  static const String submissionsCol = 'submissions';
  static const String progressCol = 'progress_updates';
  static const String notificationsCol = 'notifications';
}

enum UserRole { parent, teacher, child }

enum AssignmentStatus { pending, submitted, reviewed }

enum ReviewStatus { approved, needsImprovement }

enum ParentType { father, mother, other }

extension UserRoleExt on UserRole {
  String get label {
    switch (this) {
      case UserRole.parent:
        return 'Parent';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.child:
        return 'Student';
    }
  }

  String get value {
    switch (this) {
      case UserRole.parent:
        return 'parent';
      case UserRole.teacher:
        return 'teacher';
      case UserRole.child:
        return 'child';
    }
  }

  Color get color {
    switch (this) {
      case UserRole.parent:
        return const Color(0xFF7C4DFF);
      case UserRole.teacher:
        return const Color(0xFF00BCD4);
      case UserRole.child:
        return const Color(0xFFFF6B6B);
    }
  }

  static UserRole fromString(String v) {
    switch (v) {
      case 'parent':
        return UserRole.parent;
      case 'teacher':
        return UserRole.teacher;
      case 'child':
        return UserRole.child;
      default:
        return UserRole.child;
    }
  }
}
