import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/presence_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/presence_widgets.dart';
import '../auth/auth_gate.dart';
import '../chat/chat_screen.dart';
import '../chat/new_chat_dialog.dart';
import '../groups/create_group_screen.dart';
import '../orvex/orvex_account_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../settings/privacy_settings_screen.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const ChatsTab(),
      const GroupsTab(),
      const CallsTab(),
      const MeTab(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: Colors.white,
        elevation: 3,
        indicatorColor: AppTheme.primaryContainer,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded, color: AppTheme.primaryColor),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group_rounded, color: AppTheme.primaryColor),
            label: 'Groups',
          ),
          NavigationDestination(
            icon: Icon(Icons.call_outlined),
            selectedIcon: Icon(Icons.call_rounded, color: AppTheme.primaryColor),
            label: 'Calls',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: AppTheme.primaryColor),
            label: 'Me',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 1. CHATS TAB (1-on-1 Chats)
// ============================================================================
class ChatsTab extends StatefulWidget {
  const ChatsTab({super.key});

  @override
  State<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<ChatsTab> {
  final ChatService _chatService = ChatService();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  List<ChatModel> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    if (_currentUid.isEmpty) return;
    final list = await _chatService.getChats(_currentUid);
    if (mounted) {
      setState(() {
        _chats = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: Tooltip(
              message: 'Orvex Tech Solutions',
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OrvexAccountScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Center(
                    child: Text(
                      'O',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        title: const Text('Chats'),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search_rounded, color: AppTheme.textPrimary),
            onPressed: () => NewChatSheet.show(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: _loadChats,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
            : _chats.isEmpty
                ? _buildEmptyView()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _chats.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, indent: 76, color: AppTheme.borderColor),
                    itemBuilder: (context, index) {
                      final chat = _chats[index];
                      final peer = chat.getPeerDetails(_currentUid);
                      final peerName = peer['name'] ?? 'User';
                      final peerPhoto = peer['photoUrl'] ?? '';
                      final timeStr = chat.lastMessageTime != null
                          ? DateFormat('h:mm a').format(chat.lastMessageTime!)
                          : '';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 6),
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundColor: AppTheme.primaryContainer,
                          backgroundImage: peerPhoto.isNotEmpty
                              ? NetworkImage(peerPhoto)
                              : null,
                          child: peerPhoto.isEmpty
                              ? Text(
                                  peerName.isNotEmpty
                                      ? peerName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppTheme.primaryColor,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(
                          peerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          chat.lastMessage.isNotEmpty
                              ? chat.lastMessage
                              : 'Started a new conversation',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: chat.unreadCount > 0
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                            fontWeight: chat.unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              timeStr,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            if (chat.unreadCount > 0) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${chat.unreadCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                chatId: chat.id,
                                title: peerName,
                                photoUrl: peerPhoto,
                              ),
                            ),
                          );
                          _loadChats();
                        },
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.chat_bubble_outline_rounded),
        label: const Text(
          'New Chat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          await NewChatSheet.show(context);
          _loadChats();
        },
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.forum_outlined,
                size: 50,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Conversations Yet',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connect with friends and colleagues by starting your first chat.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 2. GROUPS TAB
// ============================================================================
class GroupsTab extends StatefulWidget {
  const GroupsTab({super.key});

  @override
  State<GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<GroupsTab> {
  final ChatService _chatService = ChatService();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  List<GroupModel> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    if (_currentUid.isEmpty) return;
    final list = await _chatService.getGroups(_currentUid);
    if (mounted) {
      setState(() {
        _groups = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Groups'),
        actions: [
          IconButton(
            tooltip: 'Create Group',
            icon: const Icon(Icons.group_add_outlined, color: AppTheme.textPrimary),
            onPressed: () async {
              final created = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
              );
              if (created == true) _loadGroups();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: _loadGroups,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
            : _groups.isEmpty
                ? _buildEmptyView()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _groups.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, indent: 76, color: AppTheme.borderColor),
                    itemBuilder: (context, index) {
                      final group = _groups[index];
                      final timeStr = group.lastMessageTime != null
                          ? DateFormat('h:mm a').format(group.lastMessageTime!)
                          : '';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 6),
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundColor: AppTheme.primaryContainer,
                          backgroundImage: group.iconUrl.isNotEmpty
                              ? NetworkImage(group.iconUrl)
                              : null,
                          child: group.iconUrl.isEmpty
                              ? const Icon(
                                  Icons.group_rounded,
                                  color: AppTheme.primaryColor,
                                  size: 26,
                                )
                              : null,
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                group.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${group.members.length}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          group.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        trailing: Text(
                          timeStr,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                chatId: group.id,
                                title: group.name,
                                photoUrl: group.iconUrl,
                                isGroup: true,
                                memberCount: group.members.length,
                              ),
                            ),
                          );
                          _loadGroups();
                        },
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.group_add_rounded),
        label: const Text(
          'New Group',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
          );
          if (created == true) _loadGroups();
        },
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.groups_3_outlined,
                size: 50,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Groups Yet',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a group to plan, discuss, and stay in touch with everyone together.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 3. CALLS TAB
// ============================================================================
class CallsTab extends StatefulWidget {
  const CallsTab({super.key});

  @override
  State<CallsTab> createState() => _CallsTabState();
}

class _CallsTabState extends State<CallsTab> {
  final ChatService _chatService = ChatService();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  List<CallLogModel> _callLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCallLogs();
  }

  Future<void> _loadCallLogs() async {
    if (_currentUid.isEmpty) return;
    final list = await _chatService.getCallLogs(_currentUid);
    if (mounted) {
      setState(() {
        _callLogs = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Calls'),
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: _loadCallLogs,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
            : _callLogs.isEmpty
                ? _buildEmptyView()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _callLogs.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, indent: 76, color: AppTheme.borderColor),
                    itemBuilder: (context, index) {
                      final call = _callLogs[index];
                      final isCaller = call.callerId == _currentUid;
                      final name = isCaller ? call.receiverName : call.callerName;
                      final photo = isCaller ? call.receiverPhoto : call.callerPhoto;
                      final timeStr = DateFormat('MMM d, h:mm a').format(call.timestamp);

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 6),
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundColor: AppTheme.primaryContainer,
                          backgroundImage:
                              photo.isNotEmpty ? NetworkImage(photo) : null,
                          child: photo.isEmpty
                              ? Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppTheme.primaryColor,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: call.isMissed
                                ? AppTheme.errorColor
                                : AppTheme.textPrimary,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Icon(
                              isCaller
                                  ? Icons.call_made_rounded
                                  : (call.isMissed
                                      ? Icons.call_missed_rounded
                                      : Icons.call_received_rounded),
                              size: 14,
                              color: call.isMissed
                                  ? AppTheme.errorColor
                                  : const Color(0xFF22C55E),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeStr,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            call.isVideo
                                ? Icons.videocam_outlined
                                : Icons.call_outlined,
                            color: AppTheme.primaryColor,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Calling $name...'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.phone_missed_rounded,
                size: 50,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Call History',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your incoming and outgoing voice and video calls will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 4. ME TAB (Profile & Settings)
// ============================================================================
class MeTab extends StatelessWidget {
  const MeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final String currentUid = currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        actions: [
          IconButton(
            tooltip: 'Log Out',
            icon: const Icon(Icons.logout_rounded, color: AppTheme.errorColor),
            onPressed: () => _confirmSignOut(context),
          ),
        ],
      ),
      body: StreamBuilder<UserModel?>(
        stream: currentUid.isNotEmpty
            ? PresenceService().streamUser(currentUid)
            : const Stream.empty(),
        builder: (context, snapshot) {
          final userModel = snapshot.data;
          final displayName = userModel?.name.isNotEmpty == true
              ? userModel!.name
              : currentUser?.displayName?.isNotEmpty == true
                  ? currentUser!.displayName!
                  : currentUser?.email?.split('@').first ?? 'User';
          final emailOrPhone = currentUser?.email?.isNotEmpty == true
              ? currentUser!.email!
              : currentUser?.phoneNumber ?? '';
          final photoUrl = userModel?.photoUrl.isNotEmpty == true
              ? userModel!.photoUrl
              : currentUser?.photoURL ?? '';
          final statusMessage = userModel?.statusMessage.isNotEmpty == true
              ? userModel!.statusMessage
              : 'Hey there! I am using ChatApp';

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // User Profile Banner Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppTheme.borderRadius,
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: AppTheme.primaryContainer,
                          backgroundImage: photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl.isEmpty
                              ? Text(
                                  displayName.isNotEmpty
                                      ? displayName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                )
                              : null,
                        ),
                        const Positioned(
                          bottom: 0,
                          right: 0,
                          child: UserOnlineDot(isOnline: true, size: 16),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            emailOrPhone,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            statusMessage,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Settings Category 1
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Account & Preferences',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppTheme.borderRadius,
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.primaryContainer,
                        child: Icon(Icons.person_outline_rounded,
                            color: AppTheme.primaryColor, size: 20),
                      ),
                      title: const Text('Edit Profile',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Name, bio, profile & cover photos',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: AppTheme.textSecondary),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditProfileScreen(initialUser: userModel),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 64, color: AppTheme.borderColor),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.primaryContainer,
                        child: Icon(Icons.shield_outlined,
                            color: AppTheme.primaryColor, size: 20),
                      ),
                      title: const Text('Privacy Settings',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Last seen, profile photo, read receipts',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: AppTheme.textSecondary),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PrivacySettingsScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 64, color: AppTheme.borderColor),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.primaryContainer,
                        child: Icon(Icons.notifications_outlined,
                            color: AppTheme.primaryColor, size: 20),
                      ),
                      title: const Text('Notifications',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Message tones, alerts, vibrate',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: AppTheme.textSecondary),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notifications settings ready.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Settings Category 2
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Support & About',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppTheme.borderRadius,
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.primaryContainer,
                        child: Icon(Icons.help_outline_rounded,
                            color: AppTheme.primaryColor, size: 20),
                      ),
                      title: const Text('Help & FAQ',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: AppTheme.textSecondary),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Help & Support center.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 64, color: AppTheme.borderColor),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.primaryContainer,
                        child: Icon(Icons.info_outline_rounded,
                            color: AppTheme.primaryColor, size: 20),
                      ),
                      title: const Text('App Version',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      trailing: const Text('1.0.0+1',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Functional Logout Button
              ElevatedButton.icon(
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text('Log Out of Account'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppTheme.borderRadius,
                  ),
                ),
                onPressed: () => _confirmSignOut(context),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadius),
        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to log out of your account?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);

              // 1. Mark presence offline without blocking
              PresenceService().setOffline().catchError((_) {});

              // 2. Clear Firebase Auth session
              await AuthService().signOut();

              // 3. Clear navigation stack and return to AuthGate
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthGate()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              minimumSize: const Size(100, 42),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

