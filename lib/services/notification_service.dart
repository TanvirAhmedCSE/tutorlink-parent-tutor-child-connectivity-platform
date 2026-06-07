import 'package:awesome_notifications/awesome_notifications.dart';
import '../utils/theme.dart';

class NotificationService {
  static Future<void> init() async {
    await AwesomeNotifications().initialize(
      null, // use default app icon
      [
        NotificationChannel(
          channelKey: 'messages_channel',
          channelName: 'Messages',
          channelDescription: 'Chat messages from TutorLink',
          defaultColor: AppColors.primary,
          ledColor: AppColors.primary,
          importance: NotificationImportance.High,
          channelShowBadge: true,
        ),
        NotificationChannel(
          channelKey: 'assignments_channel',
          channelName: 'Assignments',
          channelDescription: 'Assignment notifications',
          defaultColor: AppColors.secondary,
          ledColor: AppColors.secondary,
          importance: NotificationImportance.Default,
          channelShowBadge: true,
        ),
        NotificationChannel(
          channelKey: 'progress_channel',
          channelName: 'Progress Updates',
          channelDescription: 'Progress update notifications',
          defaultColor: AppColors.accent,
          ledColor: AppColors.accent,
          importance: NotificationImportance.Default,
          channelShowBadge: false,
        ),
      ],
    );
  }

  static Future<void> requestPermission() async {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  static Future<bool> isAllowed() async {
    return await AwesomeNotifications().isNotificationAllowed();
  }

  //  New message notification
  static Future<void> showMessageNotification({
    required String senderName,
    required String groupName,
    required String message,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'messages_channel',
        title: '$senderName in $groupName',
        body: message,
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  //  New assignment notification
  static Future<void> showAssignmentNotification({
    required String teacherName,
    required String assignmentTitle,
    required String childName,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'assignments_channel',
        title: 'New Assignment for $childName',
        body: '$teacherName posted: $assignmentTitle',
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  //  Submission reviewed notification
  static Future<void> showReviewNotification({
    required String assignmentTitle,
    required String status,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'assignments_channel',
        title: 'Assignment Reviewed',
        body: '"$assignmentTitle" has been reviewed: $status',
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  //  Progress updated notification
  static Future<void> showProgressNotification({
    required String teacherName,
    required String childName,
    required String subject,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'progress_channel',
        title: 'Progress Updated',
        body: '$teacherName updated $childName\'s $subject progress',
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  static void dispose() {
    AwesomeNotifications().dispose();
  }
}
