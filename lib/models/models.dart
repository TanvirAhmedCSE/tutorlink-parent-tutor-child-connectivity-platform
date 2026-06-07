import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

//  User Model
class AppUser {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? avatarUrl;
  final DateTime createdAt;
  final String? parentType;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    required this.createdAt,
    this.parentType,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    return AppUser(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: UserRoleExt.fromString(map['role'] ?? 'child'),
      avatarUrl: map['avatarUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      parentType: map['parentType'],
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'role': role.value,
    'avatarUrl': avatarUrl,
    'createdAt': Timestamp.fromDate(createdAt),
    'parentType': parentType,
  };
}

//  Child Model
class Child {
  final String id;
  final String name;
  final String? avatarUrl;
  final List<String> parentIds;
  final List<String> teacherIds;
  final DateTime createdAt;

  Child({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.parentIds,
    required this.teacherIds,
    required this.createdAt,
  });

  factory Child.fromMap(Map<String, dynamic> map, String id) => Child(
    id: id,
    name: map['name'] ?? '',
    avatarUrl: map['avatarUrl'],
    parentIds: List<String>.from(map['parentIds'] ?? []),
    teacherIds: List<String>.from(map['teacherIds'] ?? []),
    createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'avatarUrl': avatarUrl,
    'parentIds': parentIds,
    'teacherIds': teacherIds,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

// Teacher-Child Link
class TeacherChildLink {
  final String id;
  final String teacherId;
  final String teacherName;
  final String childId;
  final String childName;
  final String subject;
  final DateTime createdAt;

  TeacherChildLink({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.childId,
    required this.childName,
    required this.subject,
    required this.createdAt,
  });

  factory TeacherChildLink.fromMap(Map<String, dynamic> map, String id) =>
      TeacherChildLink(
        id: id,
        teacherId: map['teacherId'] ?? '',
        teacherName: map['teacherName'] ?? '',
        childId: map['childId'] ?? '',
        childName: map['childName'] ?? '',
        subject: map['subject'] ?? '',
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
    'teacherId': teacherId,
    'teacherName': teacherName,
    'childId': childId,
    'childName': childName,
    'subject': subject,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

// Group Chat Model
class GroupChat {
  final String id;
  final String name;
  final String teacherId;
  final String childId;
  final List<String> memberIds;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String subject;

  GroupChat({
    required this.id,
    required this.name,
    required this.teacherId,
    required this.childId,
    required this.memberIds,
    this.lastMessage,
    this.lastMessageAt,
    required this.subject,
  });

  factory GroupChat.fromMap(Map<String, dynamic> map, String id) => GroupChat(
    id: id,
    name: map['name'] ?? '',
    teacherId: map['teacherId'] ?? '',
    childId: map['childId'] ?? '',
    memberIds: List<String>.from(map['memberIds'] ?? []),
    lastMessage: map['lastMessage'],
    lastMessageAt: (map['lastMessageAt'] as Timestamp?)?.toDate(),
    subject: map['subject'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'teacherId': teacherId,
    'childId': childId,
    'memberIds': memberIds,
    'lastMessage': lastMessage,
    'lastMessageAt': lastMessageAt != null
        ? Timestamp.fromDate(lastMessageAt!)
        : null,
    'subject': subject,
  };
}

// Message Model
class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime sentAt;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.sentAt,
  });

  factory Message.fromMap(Map<String, dynamic> map, String id) => Message(
    id: id,
    chatId: map['chatId'] ?? '',
    senderId: map['senderId'] ?? '',
    senderName: map['senderName'] ?? '',
    text: map['text'] ?? '',
    sentAt: (map['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'chatId': chatId,
    'senderId': senderId,
    'senderName': senderName,
    'text': text,
    'sentAt': Timestamp.fromDate(sentAt),
  };
}

// Assignment Model
class Assignment {
  final String id;
  final String teacherId;
  final String teacherName;
  final String childId;
  final String childName;
  final String subject;
  final String title;
  final String instructions;
  final DateTime dueDate;
  final AssignmentStatus status;
  final DateTime createdAt;

  Assignment({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.childId,
    required this.childName,
    required this.subject,
    required this.title,
    required this.instructions,
    required this.dueDate,
    required this.status,
    required this.createdAt,
  });

  factory Assignment.fromMap(Map<String, dynamic> map, String id) => Assignment(
    id: id,
    teacherId: map['teacherId'] ?? '',
    teacherName: map['teacherName'] ?? '',
    childId: map['childId'] ?? '',
    childName: map['childName'] ?? '',
    subject: map['subject'] ?? '',
    title: map['title'] ?? '',
    instructions: map['instructions'] ?? '',
    dueDate: (map['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    status: _statusFromString(map['status'] ?? 'pending'),
    createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );

  static AssignmentStatus _statusFromString(String s) {
    switch (s) {
      case 'submitted':
        return AssignmentStatus.submitted;
      case 'reviewed':
        return AssignmentStatus.reviewed;
      default:
        return AssignmentStatus.pending;
    }
  }

  String get statusString {
    switch (status) {
      case AssignmentStatus.pending:
        return 'pending';
      case AssignmentStatus.submitted:
        return 'submitted';
      case AssignmentStatus.reviewed:
        return 'reviewed';
    }
  }

  Map<String, dynamic> toMap() => {
    'teacherId': teacherId,
    'teacherName': teacherName,
    'childId': childId,
    'childName': childName,
    'subject': subject,
    'title': title,
    'instructions': instructions,
    'dueDate': Timestamp.fromDate(dueDate),
    'status': statusString,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

//  Submission Model
class Submission {
  final String id;
  final String assignmentId;
  final String childId;
  final String? comment;
  final DateTime submittedAt;
  final ReviewStatus? reviewStatus;
  final String? teacherFeedback;
  final int? marks;
  final DateTime? reviewedAt;

  Submission({
    required this.id,
    required this.assignmentId,
    required this.childId,
    this.comment,
    required this.submittedAt,
    this.reviewStatus,
    this.teacherFeedback,
    this.marks,
    this.reviewedAt,
  });

  factory Submission.fromMap(Map<String, dynamic> map, String id) => Submission(
    id: id,
    assignmentId: map['assignmentId'] ?? '',
    childId: map['childId'] ?? '',
    comment: map['comment'],
    submittedAt: (map['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    reviewStatus: map['reviewStatus'] == 'approved'
        ? ReviewStatus.approved
        : map['reviewStatus'] == 'needsImprovement'
        ? ReviewStatus.needsImprovement
        : null,
    teacherFeedback: map['teacherFeedback'],
    marks: map['marks'],
    reviewedAt: (map['reviewedAt'] as Timestamp?)?.toDate(),
  );

  Map<String, dynamic> toMap() => {
    'assignmentId': assignmentId,
    'childId': childId,
    'comment': comment,
    'submittedAt': Timestamp.fromDate(submittedAt),
    'reviewStatus': reviewStatus == ReviewStatus.approved
        ? 'approved'
        : reviewStatus == ReviewStatus.needsImprovement
        ? 'needsImprovement'
        : null,
    'teacherFeedback': teacherFeedback,
    'marks': marks,
    'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
  };
}

// Progress Update
class ProgressUpdate {
  final String id;
  final String teacherId;
  final String teacherName;
  final String childId;
  final String subject;
  final int homeworkCompletion;
  final int understanding;
  final int participation;
  final int improvement;
  final String? notes;
  final DateTime updatedAt;

  ProgressUpdate({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.childId,
    required this.subject,
    required this.homeworkCompletion,
    required this.understanding,
    required this.participation,
    required this.improvement,
    this.notes,
    required this.updatedAt,
  });

  double get overall =>
      (homeworkCompletion + understanding + participation + improvement) / 4;

  factory ProgressUpdate.fromMap(Map<String, dynamic> map, String id) =>
      ProgressUpdate(
        id: id,
        teacherId: map['teacherId'] ?? '',
        teacherName: map['teacherName'] ?? '',
        childId: map['childId'] ?? '',
        subject: map['subject'] ?? '',
        homeworkCompletion: map['homeworkCompletion'] ?? 0,
        understanding: map['understanding'] ?? 0,
        participation: map['participation'] ?? 0,
        improvement: map['improvement'] ?? 0,
        notes: map['notes'],
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
    'teacherId': teacherId,
    'teacherName': teacherName,
    'childId': childId,
    'subject': subject,
    'homeworkCompletion': homeworkCompletion,
    'understanding': understanding,
    'participation': participation,
    'improvement': improvement,
    'notes': notes,
    'updatedAt': Timestamp.fromDate(updatedAt),
  };
}
