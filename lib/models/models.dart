import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

//  User Model
class AppUser {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? avatarUrl;
  final String? secondAvatarUrl; // student only
  final int? avatarColor; // student only
  final DateTime createdAt;
  final String? parentType;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.secondAvatarUrl,
    this.avatarColor,
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
      secondAvatarUrl: map['secondAvatarUrl'],
      avatarColor: map['avatarColor'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      parentType: map['parentType'],
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'role': role.value,
    'avatarUrl': avatarUrl,
    'secondAvatarUrl': secondAvatarUrl,
    'avatarColor': avatarColor,
    'createdAt': Timestamp.fromDate(createdAt),
    'parentType': parentType,
  };
}

//  Child Model
class Child {
  final String id;
  final String name;
  final String? avatarUrl;
  final int? avatarColor; // student color from firestore
  final List<String> parentIds;
  final List<String> teacherIds;
  final DateTime createdAt;
  final String? secondAvatarUrl;

  Child({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.avatarColor,
    required this.parentIds,
    required this.teacherIds,
    required this.createdAt,
    this.secondAvatarUrl,
  });

  factory Child.fromMap(Map<String, dynamic> map, String id) => Child(
    id: id,
    name: map['name'] ?? '',
    avatarUrl: map['avatarUrl'],
    avatarColor: map['avatarColor'],
    parentIds: List<String>.from(map['parentIds'] ?? []),
    teacherIds: List<String>.from(map['teacherIds'] ?? []),
    createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    secondAvatarUrl: map['secondAvatarUrl'],
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'avatarUrl': avatarUrl,
    'avatarColor': avatarColor,
    'parentIds': parentIds,
    'teacherIds': teacherIds,
    'createdAt': Timestamp.fromDate(createdAt),
    'secondAvatarUrl': secondAvatarUrl,
  };
}

// Teacher-Child Link
class TeacherChildLink {
  final String id;
  final String teacherId;
  final String teacherName;
  final String teacherAvatarUrl; // teacher asset path
  final String childId;
  final String childName;
  final String subject;
  final DateTime createdAt;
  final String childAvatarUrl;

  TeacherChildLink({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    this.teacherAvatarUrl = '',
    required this.childId,
    required this.childName,
    required this.subject,
    required this.createdAt,
    required this.childAvatarUrl,
  });

  factory TeacherChildLink.fromMap(Map<String, dynamic> map, String id) =>
      TeacherChildLink(
        id: id,
        teacherId: map['teacherId'] ?? '',
        teacherName: map['teacherName'] ?? '',
        teacherAvatarUrl: map['teacherAvatarUrl'] ?? '',
        childId: map['childId'] ?? '',
        childName: map['childName'] ?? '',
        subject: map['subject'] ?? '',
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        childAvatarUrl: map['childAvatarUrl'] ?? '',
      );

  Map<String, dynamic> toMap() => {
    'teacherId': teacherId,
    'teacherName': teacherName,
    'teacherAvatarUrl': teacherAvatarUrl,
    'childId': childId,
    'childName': childName,
    'subject': subject,
    'createdAt': Timestamp.fromDate(createdAt),
    'childAvatarUrl': childAvatarUrl,
  };
}

// Group Chat Model
class GroupChat {
  final String id;
  final String name;
  final String teacherId;
  final String teacherAvatarUrl; // teacher asset path
  final String childId;
  final List<String> memberIds;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String subject;

  GroupChat({
    required this.id,
    required this.name,
    required this.teacherId,
    this.teacherAvatarUrl = '',
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
    teacherAvatarUrl: map['teacherAvatarUrl'] ?? '',
    childId: map['childId'] ?? '',
    memberIds: List<String>.from(map['memberIds'] ?? []),
    lastMessage: map['lastMessage'],
    lastMessageAt: (map['lastMessageAt'] as Timestamp?)?.toDate(),
    subject: map['subject'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'teacherId': teacherId,
    'teacherAvatarUrl': teacherAvatarUrl,
    'childId': childId,
    'memberIds': memberIds,
    'lastMessage': lastMessage,
    'lastMessageAt': lastMessageAt != null
        ? Timestamp.fromDate(lastMessageAt!)
        : null,
    'subject': subject,
  };
}

//  Attachment Model
class ChatAttachment {
  final String url;
  final String filename;
  final String type; // 'image', 'file'

  ChatAttachment({
    required this.url,
    required this.filename,
    required this.type,
  });

  bool get isImage => type == 'image';

  factory ChatAttachment.fromMap(Map<String, dynamic> map) => ChatAttachment(
    url: map['url'] ?? '',
    filename: map['filename'] ?? '',
    type: map['type'] ?? 'file',
  );

  Map<String, dynamic> toMap() => {
    'url': url,
    'filename': filename,
    'type': type,
  };
}

//  AssignmentAttachment Model
class AssignmentAttachment {
  final String url;
  final String filename;
  final String type;

  AssignmentAttachment({
    required this.url,
    required this.filename,
    required this.type,
  });

  bool get isImage => type == 'image';

  factory AssignmentAttachment.fromMap(Map<String, dynamic> map) =>
      AssignmentAttachment(
        url: map['url'] ?? '',
        filename: map['filename'] ?? '',
        type: map['type'] ?? 'file',
      );

  Map<String, dynamic> toMap() => {
    'url': url,
    'filename': filename,
    'type': type,
  };
}

// Message Model
class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String senderAvatarUrl; // asset path
  final String text;
  final DateTime sentAt;
  final List<ChatAttachment> attachments;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl = '',
    required this.text,
    required this.sentAt,
    this.attachments = const [],
  });

  factory Message.fromMap(Map<String, dynamic> map, String id) => Message(
    id: id,
    chatId: map['chatId'] ?? '',
    senderId: map['senderId'] ?? '',
    senderName: map['senderName'] ?? '',
    senderAvatarUrl: map['senderAvatarUrl'] ?? '',
    text: map['text'] ?? '',
    sentAt: (map['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    attachments: (map['attachments'] as List<dynamic>? ?? [])
        .map((e) => ChatAttachment.fromMap(Map<String, dynamic>.from(e)))
        .toList(),
  );

  Map<String, dynamic> toMap() => {
    'chatId': chatId,
    'senderId': senderId,
    'senderName': senderName,
    'senderAvatarUrl': senderAvatarUrl,
    'text': text,
    'sentAt': Timestamp.fromDate(sentAt),
    'attachments': attachments.map((a) => a.toMap()).toList(),
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
  final List<AssignmentAttachment> attachments;

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
    this.attachments = const [],
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
    attachments: (map['attachments'] as List<dynamic>? ?? [])
        .map((e) => AssignmentAttachment.fromMap(Map<String, dynamic>.from(e)))
        .toList(),
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
    'attachments': attachments.map((a) => a.toMap()).toList(),
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
  final List<AssignmentAttachment> attachments;

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
    this.attachments = const [],
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
    attachments: (map['attachments'] as List<dynamic>? ?? [])
        .map((e) => AssignmentAttachment.fromMap(Map<String, dynamic>.from(e)))
        .toList(),
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
    'attachments': attachments.map((a) => a.toMap()).toList(),
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
  final String teacherSubject;

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
    required this.teacherSubject,
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
        teacherSubject: map['teacherSubject'] ?? '',
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
    'teacherSubject': teacherSubject,
  };
}
