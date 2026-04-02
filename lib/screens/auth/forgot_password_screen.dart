import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'auth_widgets.dart';

// ─── FORGOT PASSWORD SCREEN ───────────────────────────────────────────────────

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _sent = false, _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.darkText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _sent
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                            color: AppColors.peach.withOpacity(0.3),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.mark_email_read_outlined,
                            color: AppColors.coral, size: 40),
                      ),
                      const SizedBox(height: 20),
                      const Text('Check your inbox',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.darkText)),
                      const SizedBox(height: 8),
                      const Text('Reset link sent to your email.',
                          style: TextStyle(color: AppColors.warmGray),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 28),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text('Back to log in',
                            style: TextStyle(
                                color: AppColors.coral,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Reset password',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkText)),
                    const SizedBox(height: 8),
                    const Text("We'll send a reset link to your email.",
                        style:
                            TextStyle(fontSize: 15, color: AppColors.warmGray)),
                    const SizedBox(height: 32),
                    AuthField(
                        label: 'Email',
                        hint: 'jane@email.com',
                        controller: _email,
                        keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.coral,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('Send Reset Link',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16)),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    // await ApiService().forgotPassword(_email.text.trim());
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _loading = false;
      _sent = true;
    });
  }
}
