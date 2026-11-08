import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'widgets/primary_button.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;
  final String destination; // e.g. Phone number or email
  final int? resendToken;

  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.destination,
    this.resendToken,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final int _otpLength = 6;
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  final AuthService _authService = AuthService();

  late String _currentVerificationId;
  bool _isLoading = false;
  int _secondsRemaining = 60;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCountdownTimer() {
    setState(() => _secondsRemaining = 60);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _enteredCode {
    return _controllers.map((c) => c.text).join();
  }

  Future<void> _handleVerify() async {
    final code = _enteredCode;
    if (code.length < _otpLength) {
      _showSnackbar('Please enter all $_otpLength digits of the code.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signInWithOtp(
        verificationId: _currentVerificationId,
        smsCode: code,
      );

      if (!mounted) return;
      _showSnackbar('Verification successful!');
      // Pop all until root (AuthGate will redirect to Home automatically)
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      _showSnackbar(AuthService.getReadableErrorMessage(e), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleResendOtp() async {
    if (_secondsRemaining > 0) return;

    setState(() => _isLoading = true);

    await _authService.verifyPhoneNumber(
      phoneNumber: widget.destination,
      onCodeSent: (newVerificationId, _) {
        if (!mounted) return;
        setState(() {
          _currentVerificationId = newVerificationId;
          _isLoading = false;
        });
        _startCountdownTimer();
        _showSnackbar('A new verification code has been sent!');
      },
      onError: (errorMessage) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showSnackbar(errorMessage, isError: true);
      },
      onAutoVerify: (_) {},
    );
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildDigitBox(int index) {
    final bool isFilled = _controllers[index].text.isNotEmpty;

    return SizedBox(
      width: 48,
      height: 56,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
        inputFormatters: [
          LengthLimitingTextInputFormatter(6),
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          fillColor: isFilled ? AppTheme.primaryContainer : Colors.white,
          filled: true,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isFilled ? AppTheme.primaryColor : AppTheme.borderColor,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppTheme.primaryColor,
              width: 2.2,
            ),
          ),
        ),
        onChanged: (value) {
          if (value.length > 1) {
            // User pasted multi-digit code
            final digits = value.replaceAll(RegExp(r'\D'), '');
            for (int i = 0; i < _otpLength; i++) {
              if (i < digits.length) {
                _controllers[i].text = digits[i];
              }
            }
            final lastIndex = digits.length >= _otpLength ? _otpLength - 1 : digits.length;
            _focusNodes[lastIndex].requestFocus();
            if (digits.length >= _otpLength) {
              _focusNodes[lastIndex].unfocus();
              _handleVerify();
            }
            setState(() {});
            return;
          }

          if (value.isNotEmpty) {
            if (index < _otpLength - 1) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _focusNodes[index].unfocus();
              // Auto-submit when all 6 digits are typed
              if (_enteredCode.length == _otpLength) {
                _handleVerify();
              }
            }
          } else {
            if (index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          }
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              // Header Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  color: AppTheme.primaryColor,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),

              // Title & Subtitle
              const Text(
                'OTP Verification',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'We sent a 6-digit verification code to\n'),
                    TextSpan(
                      text: widget.destination,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // 6 PIN digit boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  _otpLength,
                  (index) => _buildDigitBox(index),
                ),
              ),
              const SizedBox(height: 36),

              // Primary Action
              PrimaryButton(
                text: 'Verify & Proceed',
                isLoading: _isLoading,
                onPressed: _handleVerify,
              ),
              const SizedBox(height: 24),

              // Countdown / Resend Option
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Didn't receive code? ",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  _secondsRemaining > 0
                      ? Text(
                          'Resend in ${_secondsRemaining}s',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : TextButton(
                          onPressed: _isLoading ? null : _handleResendOtp,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Resend OTP',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

