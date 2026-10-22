
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import 'admin_dashboard.dart';
import 'parent_dashboard.dart';
import 'child_dashboard.dart';

class OtpScreen extends StatefulWidget {
  final String challengeId;

  const OtpScreen({
    super.key,
    required this.challengeId,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      _showMessage('Vui lòng nhập đủ 6 số OTP');
      return;
    }

    setState(() => _loading = true);

    try {
      final role = await AuthService.verifyOtp(
        challengeId: widget.challengeId,
        otp: otp,
      );

      if (!mounted) return;

      Widget? dashboard;

      switch (role.trim().toLowerCase()) {
        case 'admin':
          dashboard = const AdminDashboard();
          break;

        case 'parent':
          dashboard = const ParentDashboard();
          break;

        case 'child':
          dashboard = const ChildDashboard();
          break;
      }

      if (dashboard == null) {
        AuthService.logout();
        throw Exception('Vai trò không hợp lệ: $role');
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => dashboard!,
        ),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text('Email Verification'),
        backgroundColor: const Color(0xFFF6F8FC),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CircleAvatar(
                  radius: 48,
                  backgroundColor: Color(0xFFE8F0FF),
                  child: Icon(
                    Icons.mark_email_read_outlined,
                    size: 50,
                    color: Color(0xFF2563EB),
                  ),
                ),

                const SizedBox(height: 26),

                const Text(
                  'Verify Your Email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172554),
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'We sent a 6-digit code to your email.\n'
                      'Enter the code to continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.blueGrey,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Code expires in 5 minutes',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.orange,
                  ),
                ),

                const SizedBox(height: 35),

                TextField(
                  controller: _otpController,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [
                    AutofillHints.oneTimeCode,
                  ],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  maxLength: 6,
                  style: const TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 9,
                  ),
                  decoration: InputDecoration(
                    hintText: '000000',
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onSubmitted: (_) {
                    if (!_loading) _verifyOtp();
                  },
                ),

                const SizedBox(height: 24),

                SizedBox(
                  height: 55,
                  child: FilledButton(
                    onPressed: _loading ? null : _verifyOtp,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                        : const Text(
                      'Verify & Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                TextButton(
                  onPressed: _loading
                      ? null
                      : () => Navigator.pop(context),
                  child: const Text(
                    'Back to Sign In',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
