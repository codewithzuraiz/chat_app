import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final ProfileService _profileService = ProfileService();
  PrivacySettings _privacy = const PrivacySettings();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final profile = await _profileService.getUserProfile(user.uid);
    if (profile != null && mounted) {
      setState(() {
        _privacy = profile.privacy;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePrivacy(PrivacySettings updated) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _privacy = updated);

    try {
      await _profileService.updatePrivacySettings(
        uid: user.uid,
        privacy: updated,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Privacy settings updated'),
          backgroundColor: AppTheme.primaryColor,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update privacy settings: $e'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showOptionSelector({
    required String title,
    required String currentValue,
    required List<Map<String, String>> options,
    required ValueChanged<String> onSelected,
  }) {
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
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...options.map((opt) {
              final val = opt['value']!;
              final label = opt['label']!;
              final isSelected = currentValue == val;

              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: Text(
                  label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  onSelected(val);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatLabel(String value) {
    switch (value) {
      case 'everyone':
        return 'Everyone';
      case 'contacts':
        return 'My Contacts';
      case 'nobody':
        return 'Nobody';
      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
        title: const Text('Privacy Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'Who can see my personal info',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // Card Container for Privacy Items
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppTheme.borderRadius,
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                children: [
                  // Last Seen & Online
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.primaryContainer,
                      child: Icon(Icons.access_time_rounded, color: AppTheme.primaryColor, size: 20),
                    ),
                    title: const Text(
                      'Last Seen & Online',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    subtitle: Text(
                      _formatLabel(_privacy.lastSeen),
                      style: const TextStyle(color: AppTheme.primaryColor, fontSize: 13),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                    onTap: () {
                      _showOptionSelector(
                        title: 'Who can see my Last Seen',
                        currentValue: _privacy.lastSeen,
                        options: const [
                          {'label': 'Everyone', 'value': 'everyone'},
                          {'label': 'My Contacts', 'value': 'contacts'},
                          {'label': 'Nobody', 'value': 'nobody'},
                        ],
                        onSelected: (val) {
                          _updatePrivacy(_privacy.copyWith(lastSeen: val));
                        },
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 64, color: AppTheme.borderColor),

                  // Profile Photo
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.primaryContainer,
                      child: Icon(Icons.account_circle_outlined, color: AppTheme.primaryColor, size: 20),
                    ),
                    title: const Text(
                      'Profile Photo',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    subtitle: Text(
                      _formatLabel(_privacy.profilePhoto),
                      style: const TextStyle(color: AppTheme.primaryColor, fontSize: 13),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                    onTap: () {
                      _showOptionSelector(
                        title: 'Who can see my Profile Photo',
                        currentValue: _privacy.profilePhoto,
                        options: const [
                          {'label': 'Everyone', 'value': 'everyone'},
                          {'label': 'My Contacts', 'value': 'contacts'},
                          {'label': 'Nobody', 'value': 'nobody'},
                        ],
                        onSelected: (val) {
                          _updatePrivacy(_privacy.copyWith(profilePhoto: val));
                        },
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 64, color: AppTheme.borderColor),

                  // Bio / About
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.primaryContainer,
                      child: Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor, size: 20),
                    ),
                    title: const Text(
                      'Bio & About',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    subtitle: Text(
                      _formatLabel(_privacy.bio),
                      style: const TextStyle(color: AppTheme.primaryColor, fontSize: 13),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                    onTap: () {
                      _showOptionSelector(
                        title: 'Who can see my Bio',
                        currentValue: _privacy.bio,
                        options: const [
                          {'label': 'Everyone', 'value': 'everyone'},
                          {'label': 'My Contacts', 'value': 'contacts'},
                          {'label': 'Nobody', 'value': 'nobody'},
                        ],
                        onSelected: (val) {
                          _updatePrivacy(_privacy.copyWith(bio: val));
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'Messaging',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // Read Receipts Switch Container
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppTheme.borderRadius,
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: SwitchListTile(
                secondary: const CircleAvatar(
                  backgroundColor: AppTheme.primaryContainer,
                  child: Icon(Icons.done_all_rounded, color: AppTheme.primaryColor, size: 20),
                ),
                title: const Text(
                  'Read Receipts',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                subtitle: const Text(
                  'If turned off, you won\'t send or receive Read Receipts.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                activeThumbColor: AppTheme.primaryColor,
                activeTrackColor: AppTheme.primaryContainer,
                value: _privacy.readReceipts,
                onChanged: (val) {
                  _updatePrivacy(_privacy.copyWith(readReceipts: val));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

