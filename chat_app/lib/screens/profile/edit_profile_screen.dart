import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model.dart';
import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';
import '../auth/widgets/custom_text_field.dart';
import '../auth/widgets/primary_button.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel? initialUser;

  const EditProfileScreen({super.key, this.initialUser});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _statusController = TextEditingController();

  final ProfileService _profileService = ProfileService();
  final ImagePicker _picker = ImagePicker();

  File? _newProfileImage;
  File? _newCoverImage;
  String _currentPhotoUrl = '';
  String _currentCoverUrl = '';

  bool _isLoading = false;
  bool _isFetchingInitialData = true;

  final List<String> _statusPresets = [
    'Hey there! I am using ChatApp',
    'Available',
    'Busy',
    'At work',
    'In a meeting',
    'Sleeping',
    'Battery about to die',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    if (widget.initialUser != null) {
      _populateUser(widget.initialUser!);
      setState(() => _isFetchingInitialData = false);
      return;
    }

    final profile = await _profileService.getUserProfile(currentUser.uid);
    if (profile != null) {
      _populateUser(profile);
    } else {
      _nameController.text = currentUser.displayName ?? '';
      _currentPhotoUrl = currentUser.photoURL ?? '';
      _statusController.text = 'Hey there! I am using ChatApp';
    }

    if (mounted) {
      setState(() => _isFetchingInitialData = false);
    }
  }

  void _populateUser(UserModel user) {
    _nameController.text = user.name;
    _bioController.text = user.bio;
    _statusController.text = user.statusMessage.isNotEmpty
        ? user.statusMessage
        : 'Hey there! I am using ChatApp';
    _currentPhotoUrl = user.photoUrl;
    _currentCoverUrl = user.coverUrl;
  }

  Future<void> _pickImage({
    required bool isProfile,
    required ImageSource source,
  }) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: isProfile ? 800 : 1600,
        maxHeight: isProfile ? 800 : 900,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        if (isProfile) {
          _newProfileImage = File(pickedFile.path);
        } else {
          _newCoverImage = File(pickedFile.path);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showImageSourceDialog({required bool isProfile}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Text(
              isProfile ? 'Change Profile Picture' : 'Change Cover Photo',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.primaryContainer,
                child: Icon(Icons.camera_alt_outlined, color: AppTheme.primaryColor),
              ),
              title: const Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(isProfile: isProfile, source: ImageSource.camera);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.primaryContainer,
                child: Icon(Icons.photo_library_outlined, color: AppTheme.primaryColor),
              ),
              title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(isProfile: isProfile, source: ImageSource.gallery);
              },
            ),
            if ((isProfile && (_newProfileImage != null || _currentPhotoUrl.isNotEmpty)) ||
                (!isProfile && (_newCoverImage != null || _currentCoverUrl.isNotEmpty)))
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.errorColor.withValues(alpha: 0.1),
                  child: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor),
                ),
                title: const Text(
                  'Remove Photo',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.errorColor),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    if (isProfile) {
                      _newProfileImage = null;
                      _currentPhotoUrl = '';
                    } else {
                      _newCoverImage = null;
                      _currentCoverUrl = '';
                    }
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      await _profileService.updateProfile(
        uid: currentUser.uid,
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        statusMessage: _statusController.text.trim(),
        newProfileImage: _newProfileImage,
        newCoverImage: _newCoverImage,
        currentPhotoUrl: _currentPhotoUrl,
        currentCoverUrl: _currentCoverUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully!'),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetchingInitialData) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Cover and Overlapping Avatar
                _buildCoverAndAvatarHeader(),
                const SizedBox(height: 60),

                // Form Fields
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full Name
                      CustomTextField(
                        controller: _nameController,
                        label: 'Username / Full Name',
                        hint: 'John Doe',
                        prefixIcon: Icons.person_outline_rounded,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Bio Field
                      Text(
                        'Bio',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _bioController,
                        maxLines: 3,
                        maxLength: 140,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Tell the world a little about yourself...',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Custom Status Message
                      CustomTextField(
                        controller: _statusController,
                        label: 'Status Message',
                        hint: 'Hey there! I am using ChatApp',
                        prefixIcon: Icons.edit_note_rounded,
                      ),
                      const SizedBox(height: 10),

                      // Status Quick Presets
                      const Text(
                        'Quick presets:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _statusPresets.map((preset) {
                          final isSelected = _statusController.text == preset;
                          return ChoiceChip(
                            label: Text(
                              preset,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppTheme.primaryContainer,
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
                            ),
                            onSelected: (_) {
                              setState(() {
                                _statusController.text = preset;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 36),

                      // Save Changes Button
                      PrimaryButton(
                        text: 'Save Changes',
                        isLoading: _isLoading,
                        onPressed: _handleSave,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoverAndAvatarHeader() {
    final double coverHeight = 160;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover Photo Container
        GestureDetector(
          onTap: () => _showImageSourceDialog(isProfile: false),
          child: Container(
            height: coverHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF4CAF50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              image: _newCoverImage != null
                  ? DecorationImage(
                      image: FileImage(_newCoverImage!),
                      fit: BoxFit.cover,
                    )
                  : (_currentCoverUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(_currentCoverUrl),
                          fit: BoxFit.cover,
                        )
                      : null),
            ),
            child: Container(
              color: Colors.black.withValues(alpha: 0.15),
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.camera_alt_outlined, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Edit Cover',
                          style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Circular Profile Picture overlapping the cover
        Positioned(
          bottom: -50,
          left: 24,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primaryContainer,
                  backgroundImage: _newProfileImage != null
                      ? FileImage(_newProfileImage!) as ImageProvider
                      : (_currentPhotoUrl.isNotEmpty ? NetworkImage(_currentPhotoUrl) : null),
                  child: (_newProfileImage == null && _currentPhotoUrl.isEmpty)
                      ? Text(
                          _nameController.text.isNotEmpty
                              ? _nameController.text[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : null,
                ),
              ),

              // Camera Edit Badge Icon
              Positioned(
                bottom: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () => _showImageSourceDialog(isProfile: true),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

