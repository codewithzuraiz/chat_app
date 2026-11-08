import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';
import '../chat/chat_screen.dart';

class OrvexAccountScreen extends StatefulWidget {
  const OrvexAccountScreen({super.key});

  @override
  State<OrvexAccountScreen> createState() => _OrvexAccountScreenState();
}

class _OrvexAccountScreenState extends State<OrvexAccountScreen> {
  final ChatService _chatService = ChatService();
  bool _isOpeningChat = false;

  final UserModel _orvexUser = const UserModel(
    uid: 'orvex_tech_official',
    name: 'Orvex Tech Solutions',
    email: 'contact@orvextech.com',
    bio:
        'Official Account of Orvex Tech Solutions. We craft next-generation mobile apps, modern web platforms, and intelligent software systems.',
    statusMessage: 'Transforming ideas into digital reality 🚀',
    isOnline: true,
  );

  @override
  void initState() {
    super.initState();
    _ensureOrvexAccountInFirestore();
  }

  /// Ensure Orvex Tech Solutions exists in Firestore so chat works seamlessly
  Future<void> _ensureOrvexAccountInFirestore() async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_orvexUser.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        await docRef.set({
          'uid': _orvexUser.uid,
          'name': _orvexUser.name,
          'email': _orvexUser.email,
          'bio': _orvexUser.bio,
          'statusMessage': _orvexUser.statusMessage,
          'isOnline': true,
          'photoUrl': '',
          'lastSeen': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  Future<void> _openChatWithOrvex() async {
    final currentFirebaseUser = FirebaseAuth.instance.currentUser;
    if (currentFirebaseUser == null) return;

    setState(() => _isOpeningChat = true);

    try {
      final currentUser = UserModel(
        uid: currentFirebaseUser.uid,
        name: currentFirebaseUser.displayName ?? 'User',
        email: currentFirebaseUser.email ?? '',
        photoUrl: currentFirebaseUser.photoURL ?? '',
      );

      final chat = await _chatService.getOrCreateChat(
        currentUser: currentUser,
        peerUser: _orvexUser,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chat.id,
            title: _orvexUser.name,
            photoUrl: '',
            peerUser: _orvexUser,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open chat: $e'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isOpeningChat = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Orvex Tech Solutions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Cover & Avatar Banner
              _buildBrandHeader(),
              const SizedBox(height: 52),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Business Title & Verified Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Orvex Tech Solutions',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.verified_rounded,
                          color: Colors.blue.shade600,
                          size: 22,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Official Verified Partner',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tagline
                    Text(
                      _orvexUser.statusMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Primary Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: _isOpeningChat
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.chat_bubble_rounded, size: 18),
                            label: const Text('Message Us'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _isOpeningChat ? null : _openChatWithOrvex,
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.mail_outline_rounded,
                              size: 18, color: AppTheme.primaryColor),
                          label: const Text('Contact',
                              style: TextStyle(color: AppTheme.primaryColor)),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(110, 48),
                            side: const BorderSide(
                                color: AppTheme.primaryColor, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                title: const Text('Contact Information',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                                content: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Email: contact@orvextech.com',
                                        style: TextStyle(fontSize: 14)),
                                    SizedBox(height: 8),
                                    Text('Website: www.orvextech.com',
                                        style: TextStyle(fontSize: 14)),
                                    SizedBox(height: 8),
                                    Text('Location: Karachi, Pakistan',
                                        style: TextStyle(fontSize: 14)),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // About Card
                    _buildSectionCard(
                      title: 'About Orvex Tech',
                      icon: Icons.info_outline_rounded,
                      child: Text(
                        _orvexUser.bio,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Services Card
                    _buildSectionCard(
                      title: 'Our Expertise & Services',
                      icon: Icons.lightbulb_outline_rounded,
                      child: Column(
                        children: [
                          _buildServiceItem(
                            icon: Icons.phone_android_rounded,
                            title: 'Mobile App Development',
                            description: 'High-performance Flutter, iOS & Android applications.',
                          ),
                          const Divider(height: 18, color: AppTheme.borderColor),
                          _buildServiceItem(
                            icon: Icons.language_rounded,
                            title: 'Web & Cloud Platforms',
                            description: 'Scalable web apps, modern APIs & Firebase cloud architectures.',
                          ),
                          const Divider(height: 18, color: AppTheme.borderColor),
                          _buildServiceItem(
                            icon: Icons.smart_toy_outlined,
                            title: 'AI Integrations & Automations',
                            description: 'Intelligent AI assistants, chatbots, and smart automations.',
                          ),
                          const Divider(height: 18, color: AppTheme.borderColor),
                          _buildServiceItem(
                            icon: Icons.design_services_outlined,
                            title: 'UI/UX & Product Design',
                            description: 'Clean, modern, and user-centric interfaces.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover container with high-tech gradient
        Container(
          height: 140,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0F3D17),
                Color(0xFF1B5E20),
                Color(0xFF2E7D32),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Brand Logo Circle
        Positioned(
          bottom: -44,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'O',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.borderRadius,
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildServiceItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppTheme.primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

