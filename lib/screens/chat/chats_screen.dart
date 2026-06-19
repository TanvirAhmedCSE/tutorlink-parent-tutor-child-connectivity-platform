import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';
import '../../widgets/widgets.dart';
import '../auth/setup_profile_picture_screen.dart';
import 'chat_room_screen.dart';

class ChatsScreen extends StatelessWidget {
  final AppUser user;
  final _fs = FirestoreService();

  ChatsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Chats'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<GroupChat>>(
        stream: _fs.userChatsStream(user.uid, user.role.name),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const AppLoading();
          }

          final chats = snap.data ?? [];
          if (chats.isEmpty) {
            return const EmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'No chats yet',
              subtitle: 'Your group chats with teachers will appear here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: chats.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 72, endIndent: 20),
            itemBuilder: (context, i) {
              final chat = chats[i];
              return _ChatTile(chat: chat, currentUser: user);
            },
          );
        },
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final GroupChat chat;
  final AppUser currentUser;

  const _ChatTile({required this.chat, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: chat.teacherAvatarUrl.isNotEmpty
          ? RectAvatar(
              imagePath: chat.teacherAvatarUrl,
              name: chat.name,
              width: 40,
              height: 52,
              borderRadius: 10,
            )
          // fallback: subject initial in a rectangle
          : Container(
              width: 40,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primaryFaint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  chat.subject.isNotEmpty ? chat.subject[0].toUpperCase() : 'G',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
      title: Text(
        chat.name,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: chat.lastMessage != null
          ? Text(
              chat.lastMessage!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            )
          : const Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textHint,
                fontStyle: FontStyle.italic,
              ),
            ),
      trailing: chat.lastMessageAt != null
          ? Text(
              timeago.format(chat.lastMessageAt!, locale: 'en_short'),
              style: const TextStyle(fontSize: 11, color: AppColors.textHint),
            )
          : null,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(chat: chat, currentUser: currentUser),
        ),
      ),
    );
  }
}
