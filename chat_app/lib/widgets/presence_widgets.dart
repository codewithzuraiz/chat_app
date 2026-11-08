import 'package:flutter/material.dart';
import '../services/presence_service.dart';
import '../theme/app_theme.dart';

class UserOnlineDot extends StatelessWidget {
  final bool isOnline;
  final double size;
  final bool showBorder;

  const UserOnlineDot({
    super.key,
    required this.isOnline,
    this.size = 12.0,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOnline) return const SizedBox.shrink();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E), // Vibrant Green
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: Colors.white, width: 2.0)
            : null,
      ),
    );
  }
}

class UserLastSeenText extends StatelessWidget {
  final bool isOnline;
  final DateTime? lastSeen;
  final String lastSeenPrivacy;
  final TextStyle? style;

  const UserLastSeenText({
    super.key,
    required this.isOnline,
    required this.lastSeen,
    this.lastSeenPrivacy = 'everyone',
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final text = PresenceService.formatLastSeen(
      isOnline: isOnline,
      lastSeen: lastSeen,
      lastSeenPrivacy: lastSeenPrivacy,
    );

    if (text.isEmpty) return const SizedBox.shrink();

    return Text(
      text,
      style: style ??
          TextStyle(
            fontSize: 12,
            fontWeight: isOnline ? FontWeight.w600 : FontWeight.normal,
            color: isOnline ? AppTheme.primaryColor : AppTheme.textSecondary,
          ),
    );
  }
}

