import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../utils/constants.dart';
import 'notification_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  //  Users
  Future<AppUser?> getUser(String uid) async {
    final doc = await _db.collection(AppConstants.usersCol).doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.data()!, doc.id);
  }

  Stream<AppUser?> userStream(String uid) {
    return _db
        .collection(AppConstants.usersCol)
        .doc(uid)
        .snapshots()
        .map((s) => s.exists ? AppUser.fromMap(s.data()!, s.id) : null);
  }

  //  Parent-initiated linking
  Future<Map<String, dynamic>> parentCreateLink({
    required String parentId,
    required String teacherEmail,
    required String subject,
    required String childEmail,
  }) async {
    // Validate teacher
    final teacher = await getUserByEmail(teacherEmail.trim());
    if (teacher == null)
      return {
        'success': false,
        'error': 'Teacher email not found. They must register first.',
      };
    if (teacher.role != UserRole.teacher)
      return {
        'success': false,
        'error': '"$teacherEmail" is not registered as a Teacher.',
      };

    // Validate child
    final child = await getUserByEmail(childEmail.trim());
    if (child == null)
      return {
        'success': false,
        'error': 'Student email not found. They must register first.',
      };
    if (child.role != UserRole.child)
      return {
        'success': false,
        'error': '"$childEmail" is not registered as a Student.',
      };

    // Check if child already belongs to a different parent
    final childDoc = await _db
        .collection(AppConstants.childrenCol)
        .doc(child.uid)
        .get();

    if (childDoc.exists) {
      final existingParentIds = List<String>.from(
        childDoc.data()?['parentIds'] ?? [],
      );
      if (existingParentIds.isNotEmpty &&
          !existingParentIds.contains(parentId)) {
        return {
          'success': false,
          'error': 'Please enter correct email/emails of your children.',
        };
      }
    }

    // Check duplicate teacher-child link
    final existing = await _db
        .collection(AppConstants.linksCol)
        .where('teacherId', isEqualTo: teacher.uid)
        .where('childId', isEqualTo: child.uid)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty)
      return {
        'success': false,
        'error': 'This teacher is already linked to this student.',
      };

    final childrenSnap = await _db
        .collection(AppConstants.childrenCol)
        .where('parentIds', arrayContains: parentId)
        .get();
    final childIds = childrenSnap.docs.map((d) => d.id).toList();

    if (childIds.isNotEmpty) {
      final subjectTeacherLinks = await _db
          .collection(AppConstants.linksCol)
          .where('childId', whereIn: childIds)
          .where('subject', isEqualTo: subject)
          .get();

      final existingTeacherIds = subjectTeacherLinks.docs
          .map((d) => d.data()['teacherId'] as String)
          .toSet();

      if (existingTeacherIds.isNotEmpty &&
          !existingTeacherIds.contains(teacher.uid)) {
        return {
          'success': false,
          'error':
              'Only one teacher is available for one single subject. "$subject" already has a teacher assigned.',
        };
      }
    }

    final teacherExistingLinks = await _db
        .collection(AppConstants.linksCol)
        .where('teacherId', isEqualTo: teacher.uid)
        .limit(1)
        .get();

    final bool isNewTeacher = teacherExistingLinks.docs.isEmpty;

    if (!isNewTeacher) {
      final subjectMatch = await _db
          .collection(AppConstants.linksCol)
          .where('teacherId', isEqualTo: teacher.uid)
          .where('subject', isEqualTo: subject)
          .limit(1)
          .get();

      if (subjectMatch.docs.isEmpty) {
        final allLinks = await _db
            .collection(AppConstants.linksCol)
            .where('teacherId', isEqualTo: teacher.uid)
            .get();
        final subjects = allLinks.docs
            .map((d) => d.data()['subject'] as String)
            .toSet()
            .toList();
        return {
          'success': false,
          'error':
              'Subject mismatch. ${teacher.name} teaches: ${subjects.join(', ')}. Use the exact subject name.',
        };
      }
    }

    // Create link
    final teacherUserDoc = await _db
        .collection(AppConstants.usersCol)
        .doc(teacher.uid)
        .get();
    final teacherAvatarUrl = teacherUserDoc.data()?['avatarUrl'] ?? '';
    final childUserDoc = await _db
        .collection(AppConstants.usersCol)
        .doc(child.uid)
        .get();
    final childAvatarUrl = childUserDoc.data()?['avatarUrl'] ?? '';
    final linkRef = _db.collection(AppConstants.linksCol).doc();
    await linkRef.set(
      TeacherChildLink(
        id: linkRef.id,
        teacherId: teacher.uid,
        teacherName: teacher.name,
        teacherAvatarUrl: teacherAvatarUrl,
        childId: child.uid,
        childName: child.name,
        childAvatarUrl: childAvatarUrl,
        subject: subject,
        createdAt: DateTime.now(),
      ).toMap(),
    );

    // Update child's teacherIds
    await _db.collection(AppConstants.childrenCol).doc(child.uid).set({
      'name': child.name,
      'avatarUrl': child.avatarUrl,
      'secondAvatarUrl': child.secondAvatarUrl,
      'parentIds': FieldValue.arrayUnion([parentId]),
      'teacherIds': FieldValue.arrayUnion([teacher.uid]),
      'createdAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));

    final updatedChildDoc = await _db
        .collection(AppConstants.childrenCol)
        .doc(child.uid)
        .get();
    final parentIds = List<String>.from(
      updatedChildDoc.data()?['parentIds'] ?? [],
    );
    final memberIds = {teacher.uid, child.uid, ...parentIds}.toList();

    // Same teacher + same subject = same group chat
    final chatQuery = await _db
        .collection(AppConstants.groupChatsCol)
        .where('teacherId', isEqualTo: teacher.uid)
        .where('subject', isEqualTo: subject)
        .limit(1)
        .get();

    if (chatQuery.docs.isEmpty) {
      final chatRef = _db.collection(AppConstants.groupChatsCol).doc();
      await chatRef.set(
        GroupChat(
          id: chatRef.id,
          name: '$subject Group - ${teacher.name}',
          teacherId: teacher.uid,
          teacherAvatarUrl: teacherAvatarUrl,
          childId: child.uid,
          memberIds: memberIds,
          subject: subject,
        ).toMap(),
      );
    } else {
      await chatQuery.docs.first.reference.update({
        'memberIds': FieldValue.arrayUnion(memberIds),
      });
    }

    return {'success': true};
  }

  //  Parent's linked teachers (via children)
  Stream<List<TeacherChildLink>> parentLinksStream(String parentId) {
    return _db
        .collection(AppConstants.childrenCol)
        .where('parentIds', arrayContains: parentId)
        .snapshots()
        .asyncMap((childSnap) async {
          final childIds = childSnap.docs.map((d) => d.id).toList();
          if (childIds.isEmpty) return [];
          final linksSnap = await _db
              .collection(AppConstants.linksCol)
              .where('childId', whereIn: childIds)
              .get();
          return linksSnap.docs
              .map((d) => TeacherChildLink.fromMap(d.data(), d.id))
              .toList();
        });
  }

  Future<Child?> getChild(String childId) async {
    final doc = await _db
        .collection(AppConstants.childrenCol)
        .doc(childId)
        .get();
    if (!doc.exists) return null;
    return Child.fromMap(doc.data()!, doc.id);
  }

  Stream<List<Child>> parentChildrenStream(String parentUid) {
    return _db
        .collection(AppConstants.childrenCol)
        .where('parentIds', arrayContains: parentUid)
        .snapshots()
        .map((s) => s.docs.map((d) => Child.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<TeacherChildLink>> teacherLinksStream(String teacherId) {
    return _db
        .collection(AppConstants.linksCol)
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => TeacherChildLink.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  Stream<List<TeacherChildLink>> childLinksStream(String childId) {
    return _db
        .collection(AppConstants.linksCol)
        .where('childId', isEqualTo: childId)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => TeacherChildLink.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  //  Group Chats
  Stream<List<GroupChat>> userChatsStream(String uid, String role) async* {
    if (role == 'teacher') {
      final linksSnap = await _db
          .collection(AppConstants.linksCol)
          .where('teacherId', isEqualTo: uid)
          .get();
      for (final doc in linksSnap.docs) {
        final link = TeacherChildLink.fromMap(doc.data(), doc.id);
        await _ensureGroupChat(link);
      }
    } else if (role == 'child') {
      final linksSnap = await _db
          .collection(AppConstants.linksCol)
          .where('childId', isEqualTo: uid)
          .get();
      for (final doc in linksSnap.docs) {
        final link = TeacherChildLink.fromMap(doc.data(), doc.id);
        await _ensureGroupChat(link);
      }
    } else {
      // Parent
      final childrenSnap = await _db
          .collection(AppConstants.childrenCol)
          .where('parentIds', arrayContains: uid)
          .get();
      for (final childDoc in childrenSnap.docs) {
        final childId = childDoc.id;
        final linksSnap = await _db
            .collection(AppConstants.linksCol)
            .where('childId', isEqualTo: childId)
            .get();
        for (final doc in linksSnap.docs) {
          final link = TeacherChildLink.fromMap(doc.data(), doc.id);
          await _ensureGroupChat(link, extraMemberId: uid);
        }
      }
    }

    yield* _db
        .collection(AppConstants.groupChatsCol)
        .where('memberIds', arrayContains: uid)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => GroupChat.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) {
            final aTime = a.lastMessageAt ?? DateTime(2000);
            final bTime = b.lastMessageAt ?? DateTime(2000);
            return bTime.compareTo(aTime);
          });
          return list;
        });
  }

  Future<void> _ensureGroupChat(
    TeacherChildLink link, {
    String? extraMemberId,
  }) async {
    final existing = await _db
        .collection(AppConstants.groupChatsCol)
        .where('teacherId', isEqualTo: link.teacherId)
        .where('subject', isEqualTo: link.subject)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      final toAdd = <String>[];
      if (extraMemberId != null) toAdd.add(extraMemberId);
      toAdd.add(link.childId);

      final memberIds = List<String>.from(
        existing.docs.first.data()['memberIds'] ?? [],
      );
      final newMembers = toAdd.where((id) => !memberIds.contains(id)).toList();
      if (newMembers.isNotEmpty) {
        await existing.docs.first.reference.update({
          'memberIds': FieldValue.arrayUnion(newMembers),
        });
      }

      final existingAvatarUrl =
          existing.docs.first.data()['teacherAvatarUrl'] ?? '';
      if (existingAvatarUrl.isEmpty && link.teacherAvatarUrl.isNotEmpty) {
        await existing.docs.first.reference.update({
          'teacherAvatarUrl': link.teacherAvatarUrl,
        });
      }
      return;
    }

    final childDoc = await _db
        .collection(AppConstants.childrenCol)
        .doc(link.childId)
        .get();
    final parentIds = List<String>.from(childDoc.data()?['parentIds'] ?? []);
    final memberIds = {
      link.teacherId,
      link.childId,
      ...parentIds,
      if (extraMemberId != null) extraMemberId,
    }.toList();

    final chatRef = _db.collection(AppConstants.groupChatsCol).doc();
    await chatRef.set(
      GroupChat(
        id: chatRef.id,
        name: '${link.subject} Group - ${link.teacherName}',
        teacherId: link.teacherId,
        teacherAvatarUrl: link.teacherAvatarUrl,
        childId: link.childId,
        memberIds: memberIds,
        subject: link.subject,
      ).toMap(),
    );
  }

  //  Messages
  Future<void> sendMessage(Message message) async {
    final ref = _db
        .collection(AppConstants.groupChatsCol)
        .doc(message.chatId)
        .collection(AppConstants.messagesCol)
        .doc();

    await ref.set({
      'id': ref.id,
      'chatId': message.chatId,
      'senderId': message.senderId,
      'senderName': message.senderName,
      'text': message.text,
      'sentAt': Timestamp.fromDate(message.sentAt),
      'attachments': message.attachments.map((a) => a.toMap()).toList(),
    });

    // lastMessage preview: if text empty and has attachments, show placeholder
    final preview = message.text.isNotEmpty
        ? message.text
        : message.attachments.isNotEmpty
        ? (message.attachments.first.isImage
              ? '📷 Image'
              : '📎 ${message.attachments.first.filename}')
        : '';

    await _db.collection(AppConstants.groupChatsCol).doc(message.chatId).update(
      {
        'lastMessage': preview,
        'lastMessageAt': Timestamp.fromDate(message.sentAt),
      },
    );
  }

  Stream<List<Message>> messagesStream(String chatId) {
    return _db
        .collection(AppConstants.groupChatsCol)
        .doc(chatId)
        .collection(AppConstants.messagesCol)
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => Message.fromMap(d.data(), d.id)).toList(),
        );
  }

  Future<Assignment> createAssignment({
    required String teacherId,
    required String teacherName,
    required String childId,
    required String childName,
    required String subject,
    required String title,
    required String instructions,
    required DateTime dueDate,
    List<AssignmentAttachment> attachments = const [],
  }) async {
    final ref = _db.collection(AppConstants.assignmentsCol).doc();
    final assignment = Assignment(
      id: ref.id,
      teacherId: teacherId,
      teacherName: teacherName,
      childId: childId,
      childName: childName,
      subject: subject,
      title: title,
      instructions: instructions,
      dueDate: dueDate,
      status: AssignmentStatus.pending,
      createdAt: DateTime.now(),
      attachments: attachments,
    );
    await ref.set(assignment.toMap());

    await NotificationService.sendAssignmentNotificationToChild(
      childUid: childId,
      teacherName: teacherName,
      subject: subject,
      assignmentTitle: title,
      assignmentId: ref.id,
    );

    final childDoc = await _db
        .collection(AppConstants.childrenCol)
        .doc(childId)
        .get();
    final parentIds = List<String>.from(childDoc.data()?['parentIds'] ?? []);
    if (parentIds.isNotEmpty) {
      await NotificationService.sendAssignmentNotificationToParents(
        parentUids: parentIds,
        childName: childName,
        teacherName: teacherName,
        subject: subject,
        assignmentTitle: title,
        assignmentId: ref.id,
      );
    }

    return assignment;
  }

  Stream<List<Assignment>> teacherAssignmentsStream(String teacherId) {
    return _db
        .collection(AppConstants.assignmentsCol)
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => Assignment.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<Assignment>> childAssignmentsStream(String childId) {
    return _db
        .collection(AppConstants.assignmentsCol)
        .where('childId', isEqualTo: childId)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => Assignment.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<Assignment>> childrenAssignmentsStream(List<String> childIds) {
    if (childIds.isEmpty) return const Stream.empty();
    return _db
        .collection(AppConstants.assignmentsCol)
        .where('childId', whereIn: childIds)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => Assignment.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  //  Submissions
  Future<Submission> createSubmission({
    required String assignmentId,
    required String childId,
    String? comment,
    List<AssignmentAttachment> attachments = const [],
  }) async {
    final ref = _db.collection(AppConstants.submissionsCol).doc();
    final submission = Submission(
      id: ref.id,
      assignmentId: assignmentId,
      childId: childId,
      comment: comment,
      submittedAt: DateTime.now(),
      attachments: attachments,
    );
    await ref.set(submission.toMap());

    await _db.collection(AppConstants.assignmentsCol).doc(assignmentId).update({
      'status': 'submitted',
    });

    return submission;
  }

  Future<Submission?> getSubmission(String assignmentId) async {
    final q = await _db
        .collection(AppConstants.submissionsCol)
        .where('assignmentId', isEqualTo: assignmentId)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return Submission.fromMap(q.docs.first.data(), q.docs.first.id);
  }

  Future<void> reviewSubmission({
    required String submissionId,
    required String assignmentId,
    required ReviewStatus status,
    required String feedback,
    required int marks,
  }) async {
    await _db.collection(AppConstants.submissionsCol).doc(submissionId).update({
      'reviewStatus': status == ReviewStatus.approved
          ? 'approved'
          : 'needsImprovement',
      'teacherFeedback': feedback,
      'marks': marks,
      'reviewedAt': Timestamp.fromDate(DateTime.now()),
    });
    await _db.collection(AppConstants.assignmentsCol).doc(assignmentId).update({
      'status': 'reviewed',
    });
  }

  Future<List<Submission>> getSubmissionsForAssignment(
    String assignmentId,
  ) async {
    final q = await _db
        .collection(AppConstants.submissionsCol)
        .where('assignmentId', isEqualTo: assignmentId)
        .get();
    return q.docs.map((d) => Submission.fromMap(d.data(), d.id)).toList();
  }

  //  Progress
  Future<ProgressUpdate> upsertProgress({
    required String teacherId,
    required String teacherName,
    required String childId,
    required String subject,
    required int homework,
    required int understanding,
    required int participation,
    required int improvement,
    String? notes,
    required String teacherSubject,
  }) async {
    final q = await _db
        .collection(AppConstants.progressCol)
        .where('teacherId', isEqualTo: teacherId)
        .where('childId', isEqualTo: childId)
        .where('subject', isEqualTo: subject)
        .limit(1)
        .get();

    final data = {
      'teacherId': teacherId,
      'teacherName': teacherName,
      'childId': childId,
      'subject': subject,
      'homeworkCompletion': homework,
      'understanding': understanding,
      'participation': participation,
      'improvement': improvement,
      'notes': notes,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'teacherSubject': teacherSubject,
    };

    DocumentReference ref;
    if (q.docs.isNotEmpty) {
      ref = q.docs.first.reference;
      await ref.update(data);
    } else {
      ref = _db.collection(AppConstants.progressCol).doc();
      await ref.set(data);
    }

    final doc = await ref.get();
    return ProgressUpdate.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Stream<List<ProgressUpdate>> childProgressStream(String childId) {
    return _db
        .collection(AppConstants.progressCol)
        .where('childId', isEqualTo: childId)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => ProgressUpdate.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  Stream<List<ProgressUpdate>> teacherProgressStream(String teacherId) {
    return _db
        .collection(AppConstants.progressCol)
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => ProgressUpdate.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  //  Get user by email
  Future<AppUser?> getUserByEmail(String email) async {
    final q = await _db
        .collection(AppConstants.usersCol)
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return AppUser.fromMap(q.docs.first.data(), q.docs.first.id);
  }

  //  Fetch member details for a group chat
  Future<Map<String, AppUser>> getChatMembers(List<String> memberIds) async {
    final Map<String, AppUser> result = {};
    for (final uid in memberIds) {
      final user = await getUser(uid);
      if (user != null) result[uid] = user;
    }
    return result;
  }

  Future<void> updateUserAvatar({
    required String uid,
    required String avatarUrl,
    String? secondAvatarUrl,
    int? avatarColor,
    required UserRole role,
  }) async {
    final data = <String, dynamic>{'avatarUrl': avatarUrl};
    if (secondAvatarUrl != null) data['secondAvatarUrl'] = secondAvatarUrl;
    if (avatarColor != null) data['avatarColor'] = avatarColor;
    await _db.collection(AppConstants.usersCol).doc(uid).update(data);

    if (role == UserRole.teacher) {
      final links = await _db
          .collection(AppConstants.linksCol)
          .where('teacherId', isEqualTo: uid)
          .get();
      for (final doc in links.docs) {
        await doc.reference.update({'teacherAvatarUrl': avatarUrl});
      }
      final chats = await _db
          .collection(AppConstants.groupChatsCol)
          .where('teacherId', isEqualTo: uid)
          .get();
      for (final doc in chats.docs) {
        await doc.reference.update({'teacherAvatarUrl': avatarUrl});
      }
    } else if (role == UserRole.child) {
      final links = await _db
          .collection(AppConstants.linksCol)
          .where('childId', isEqualTo: uid)
          .get();
      for (final doc in links.docs) {
        await doc.reference.update({'childAvatarUrl': avatarUrl});
      }
      await _db.collection(AppConstants.childrenCol).doc(uid).set({
        'avatarUrl': avatarUrl,
        if (avatarColor != null) 'avatarColor': avatarColor,
        if (secondAvatarUrl != null) 'secondAvatarUrl': secondAvatarUrl,
      }, SetOptions(merge: true));
    }
  }
}
