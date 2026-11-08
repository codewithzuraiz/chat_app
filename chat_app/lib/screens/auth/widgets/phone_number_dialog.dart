import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_theme.dart';
import '../otp_screen.dart';
import 'custom_text_field.dart';
import 'primary_button.dart';

class PhoneNumberBottomSheet extends StatefulWidget {
  const PhoneNumberBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PhoneNumberBottomSheet(),
    );
  }

  @override
  State<PhoneNumberBottomSheet> createState() => _PhoneNumberBottomSheetState();
}

class _PhoneNumberBottomSheetState extends State<PhoneNumberBottomSheet> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    setState(() => _isLoading = true);

    await _authService.verifyPhoneNumber(
      phoneNumber: phone,
      onCodeSent: (verificationId, resendToken) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        Navigator.pop(context); // Close bottom sheet
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              verificationId: verificationId,
              destination: phone,
              resendToken: resendToken,
            ),
          ),
        );
      },
      onError: (errorMessage) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
      onAutoVerify: (credential) async {
        if (!mounted) return;
        try {
          await _authService.signInWithOtp(
            verificationId: credential.verificationId ?? '',
            smsCode: credential.smsCode ?? '',
          );
        } catch (_) {}
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
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
              const SizedBox(height: 20),
              const Text(
                'Phone Authentication',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Enter your phone number with country code (e.g., +1 234 567 8900) to receive an SMS verification code.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: '+1 234 567 8900',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (!value.trim().startsWith('+')) {
                    return 'Please include country code starting with +';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Send Verification Code',
                isLoading: _isLoading,
                onPressed: _handleSendOtp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

