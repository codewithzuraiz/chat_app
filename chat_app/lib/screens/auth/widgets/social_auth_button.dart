import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class SocialAuthButton extends StatelessWidget {
  final String text;
  final Widget icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  const SocialAuthButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  /// Factory constructor for Google Sign-In button
  factory SocialAuthButton.google({
    Key? key,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return SocialAuthButton(
      key: key,
      text: 'Continue with Google',
      icon: const GoogleLogoIcon(),
      onPressed: onPressed,
      isLoading: isLoading,
    );
  }

  /// Factory constructor for Phone Authentication button
  factory SocialAuthButton.phone({
    Key? key,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return SocialAuthButton(
      key: key,
      text: 'Login with Phone Number',
      icon: const Icon(
        Icons.phone_iphone_rounded,
        color: AppTheme.primaryColor,
        size: 22,
      ),
      onPressed: onPressed,
      isLoading: isLoading,
    );
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.textPrimary,
        backgroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(54),
        side: const BorderSide(color: AppTheme.borderColor, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadius,
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryColor,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 12),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
    );
  }
}

/// Official Google Logo rendered cleanly with CustomPainter (no assets needed)
class GoogleLogoIcon extends StatelessWidget {
  final double size;

  const GoogleLogoIcon({super.key, this.size = 22.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    // Outer strokes
    final strokeWidth = radius * 0.42;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final arcRect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    // Blue arc (right & top right)
    arcPaint.color = const Color(0xFF4285F4);
    canvas.drawArc(arcRect, -0.4, 1.2, false, arcPaint);

    // Green arc (bottom & bottom right)
    arcPaint.color = const Color(0xFF34A853);
    canvas.drawArc(arcRect, 0.8, 1.6, false, arcPaint);

    // Yellow arc (bottom left)
    arcPaint.color = const Color(0xFFFBBC05);
    canvas.drawArc(arcRect, 2.4, 1.2, false, arcPaint);

    // Red arc (top & top left)
    arcPaint.color = const Color(0xFFEA4335);
    canvas.drawArc(arcRect, 3.6, 1.6, false, arcPaint);

    // Blue horizontal bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final barRect = Rect.fromLTWH(
      center.dx,
      center.dy - strokeWidth / 2,
      radius,
      strokeWidth,
    );
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

