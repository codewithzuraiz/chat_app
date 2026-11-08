import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model.dart';
import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';
import '../auth/widgets/custom_text_field.dart';
import '../auth/widgets/primary_button.dart';
import '../chat/chat_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ImagePicker _picker = ImagePicker();

  File? _groupIcon;
  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  final Set<String> _selectedUserIds = {};
  bool _isLoadingUsers = true;
  bool _isCreating = false;
  StreamSubscription? _usersSub;

  @override
  void initState() {
    super.initState();
    _chatService.ensureDefaultUsersSeeded();
    _subscribeUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    _nameController.dispose();
    _descriptionController.dispose();
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
            _filterUsers();
            _isLoadingUsers = false;
          });
        }
      },
      onError: (_) {
        if (mounted) {
          setState(() => _isLoadingUsers = false);
        }
      },
    );
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      _filteredUsers = List.from(_allUsers);
    } else {
      _filteredUsers = _allUsers
          .where((u) =>
              u.name.toLowerCase().contains(query) ||
              u.email.toLowerCase().contains(query))
          .toList();
    }
  }

  Future<void> _pickGroupIcon() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() => _groupIcon = File(picked.path));
      }
    } catch (_) {}
  }

  Future<void> _handleCreateGroup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one member for the group'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    setState(() => _isCreating = true);

    try {
      final group = await _chatService.createGroup(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        iconFile: _groupIcon,
        memberIds: _selectedUserIds.toList(),
        createdBy: currentUid,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group created successfully!'),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate directly into the newly created group chat
      Navigator.pushReplacement(
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create group: $e'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Create New Group'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group Icon Picker & Name Field Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Group Icon Picker
                    GestureDetector(
                      onTap: _pickGroupIcon,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: AppTheme.primaryContainer,
                            backgroundImage: _groupIcon != null
                                ? FileImage(_groupIcon!)
                                : null,
                            child: _groupIcon == null
                                ? const Icon(
                                    Icons.group_rounded,
                                    size: 36,
                                    color: AppTheme.primaryColor,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Group Name Input
                    Expanded(
                      child: CustomTextField(
                        controller: _nameController,
                        label: 'Group Name',
                        hint: 'e.g. Flutter Devs PK',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a group name';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Group Description Field
                CustomTextField(
                  controller: _descriptionController,
                  label: 'Group Topic / Description (Optional)',
                  hint: 'What is this group about?',
                  prefixIcon: Icons.description_outlined,
                ),
                const SizedBox(height: 24),

                // Selected Members Chips Section
                if (_selectedUserIds.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Selected Members',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${_selectedUserIds.length} members',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 80,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _selectedUserIds.map((uid) {
                        final user = _allUsers.firstWhere(
                          (u) => u.uid == uid,
                          orElse: () =>
                              UserModel(uid: uid, name: 'User', email: ''),
                        );
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Column(
                            children: [
                              Stack(
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
                                    top: -2,
                                    right: -2,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(
                                            () => _selectedUserIds.remove(uid));
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: AppTheme.errorColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.name.split(' ').first,
                                style: const TextStyle(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(color: AppTheme.borderColor),
                ],

                // Choose Members Title & Search Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Participants',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${_allUsers.length} available',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Search participants input
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search people by name or email...',
                    hintStyle:
                        const TextStyle(fontSize: 13, color: AppTheme.textHint),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppTheme.textSecondary, size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // User Checklist Container
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppTheme.borderRadius,
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: _isLoadingUsers
                      ? const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.primaryColor),
                          ),
                        )
                      : _filteredUsers.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(28),
                              child: Center(
                                child: Text(
                                  'No users match your search.',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _filteredUsers.length,
                              separatorBuilder: (context, index) => const Divider(
                                  height: 1, color: AppTheme.borderColor),
                              itemBuilder: (context, index) {
                                final user = _filteredUsers[index];
                                final isSelected =
                                    _selectedUserIds.contains(user.uid);

                                return CheckboxListTile(
                                  activeColor: AppTheme.primaryColor,
                                  value: isSelected,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedUserIds.add(user.uid);
                                      } else {
                                        _selectedUserIds.remove(user.uid);
                                      }
                                    });
                                  },
                                  secondary: CircleAvatar(
                                    radius: 20,
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
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
                const SizedBox(height: 32),

                // Create Group Button
                PrimaryButton(
                  text: 'Create Group',
                  isLoading: _isCreating,
                  onPressed: _handleCreateGroup,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
