import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';
import '../utils/constants.dart';

class HiveService {
  static late Box _userBox;
  static late Box _assignmentsBox;
  static late Box _chatsBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    _userBox = await Hive.openBox(AppConstants.userBox);
    _assignmentsBox = await Hive.openBox(AppConstants.assignmentsBox);
    _chatsBox = await Hive.openBox(AppConstants.chatsBox);
  }

  //  User
  static Future<void> saveUser(AppUser user) async {
    await _userBox.put(AppConstants.currentUserKey, {
      'uid': user.uid,
      'name': user.name,
      'email': user.email,
      'role': user.role.value,
      'avatarUrl': user.avatarUrl,
      'parentType': user.parentType,
      'createdAt': user.createdAt.toIso8601String(),
    });
  }

  static AppUser? getUser() {
    final data = _userBox.get(AppConstants.currentUserKey);
    if (data == null) return null;
    final map = Map<String, dynamic>.from(data);
    return AppUser(
      uid: map['uid'],
      name: map['name'],
      email: map['email'],
      role: UserRoleExt.fromString(map['role']),
      avatarUrl: map['avatarUrl'],
      parentType: map['parentType'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  //  Assignments cache
  static Future<void> cacheAssignments(List<Map<String, dynamic>> list) async {
    await _assignmentsBox.put(AppConstants.cachedAssignmentsKey, list);
  }

  static List<Map<String, dynamic>> getCachedAssignments() {
    final data = _assignmentsBox.get(AppConstants.cachedAssignmentsKey);
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(
      (data as List).map((e) => Map<String, dynamic>.from(e)),
    );
  }

  //  Chats cache
  static Future<void> cacheChats(List<Map<String, dynamic>> list) async {
    await _chatsBox.put(AppConstants.cachedChatsKey, list);
  }

  static List<Map<String, dynamic>> getCachedChats() {
    final data = _chatsBox.get(AppConstants.cachedChatsKey);
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(
      (data as List).map((e) => Map<String, dynamic>.from(e)),
    );
  }

  //  Clear
  static Future<void> clearAll() async {
    await _userBox.clear();
    await _assignmentsBox.clear();
    await _chatsBox.clear();
  }
}
