import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';

class NotificationService {
  static const String _appId = 'XXXXXXXXXXXXXXXXXXXXX';
  static const String _restApiKey =
      'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';

  static Future<void> init() async {
    OneSignal.initialize(_appId);
    await OneSignal.Notifications.requestPermission(true);
  }

  static Future<void> loginUser(String uid) async {
    await OneSignal.login(uid);
  }

  static Future<void> logoutUser() async {
    await OneSignal.logout();
  }

  // Assignment notification — to child
  static Future<void> sendAssignmentNotificationToChild({
    required String childUid,
    required String teacherName,
    required String subject,
    required String assignmentTitle,
    required String assignmentId,
  }) async {
    await _sendPush(
      targetUids: [childUid],
      heading: 'New Assignment: $subject',
      content: '$teacherName has given a new assignment: "$assignmentTitle"',
      data: {'assignmentId': assignmentId},
    );
  }

  // Assignment notification — to parent
  static Future<void> sendAssignmentNotificationToParents({
    required List<String> parentUids,
    required String childName,
    required String teacherName,
    required String subject,
    required String assignmentTitle,
    required String assignmentId,
  }) async {
    if (parentUids.isEmpty) return;
    await _sendPush(
      targetUids: parentUids,
      heading: 'New Assignment for $childName',
      content:
          '$teacherName has assigned "$assignmentTitle" in "$subject" to $childName.',
      data: {'assignmentId': assignmentId},
    );
  }

  static Future<void> _sendPush({
    required List<String> targetUids,
    required String heading,
    required String content,
    required Map<String, dynamic> data,
  }) async {
    try {
      await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Key $_restApiKey',
        },
        body: jsonEncode({
          'app_id': _appId,
          'include_aliases': {'external_id': targetUids},
          'target_channel': 'push',
          'headings': {'en': heading},
          'contents': {'en': content},
          'data': data,
        }),
      );
    } catch (e) {
      // If notification fails, assignment will also be created — silent fail
    }
  }
}
