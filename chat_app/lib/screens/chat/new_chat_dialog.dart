import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/presence_widgets.dart';
import 'chat_screen.dart';

class NewChatSheet extends StatefulWidget {
  const NewChatSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NewChatSheet(),
    );
  }

  @override
  State<NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<NewChatSheet> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();

  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  StreamSubscription? _usersSub;

  @override
  void initState() {
    super.initState();
    _chatService.ensureDefaultUsersSeeded();
    _subscribeUsers();
    _searchController.addListener(_filter);
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _subscribeUsers() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _usersSub = _chatService.streamAllUsers(currentUid).listen(
      (users) {
        if (mounted) {
          setState(() {
            _allUsers = users;
            _filter();
            _isLoading = false;
          });
        }
      },
      onError: (_) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
    );
  }

  void _filter() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _allUsers;
      } else {
        _filteredUsers = _allUsers
            .where((u) =>
                u.name.toLowerCase().contains(query) ||
                u.email.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _startChatWithUser(UserModel peerUser) async {
    final currentFirebaseUser = FirebaseAuth.instance.currentUser;
    if (currentFirebaseUser == null) return;

    final currentUser = UserModel(
      uid: currentFirebaseUser.uid,
      name: currentFirebaseUser.displayName ?? 'User',
      email: currentFirebaseUser.email ?? '',
      photoUrl: currentFirebaseUser.photoURL ?? '',
    );

    Navigator.pop(context); // Close sheet

    final chat = await _chatService.getOrCreateChat(
      currentUser: currentUser,
      peerUser: peerUser,
    );

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chat.id,
          title: peerUser.name,
          photoUrl: peerUser.photoUrl,
          peerUser: peerUser,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.8;

    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          const Text(
            'New Conversation',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Select a contact to start chatting with',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),

          // Search Box
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search people by name...',
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppTheme.textSecondary, size: 20),
              filled: true,
              fillColor: AppTheme.backgroundColor,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Users List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  )
                : _filteredUsers.isEmpty
                    ? const Center(
                        child: Text(
                          'No registered users found.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filteredUsers.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, color: AppTheme.borderColor),
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppTheme.primaryContainer,
                                  backgroundImage: user.photoUrl.isNotEmpty
                                      ? NetworkImage(user.photoUrl)
                                      : null,
                                  child: user.photoUrl.isEmpty
                                      ? Text(
                                          user.name.isNotEmpty
                                              ? user.name[0].toUpperCase()
                                              : 'U',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryColor,
                                          ),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: UserOnlineDot(
                                    isOnline: user.isOnline,
                                    size: 13,
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              user.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              user.statusMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                            onTap: () => _startChatWithUser(user),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

