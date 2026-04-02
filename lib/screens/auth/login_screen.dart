import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'auth_widgets.dart';
import 'forgot_password_screen.dart';

// ─── LOGIN SCREEN ─────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Welcome back!',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText)),
                const SizedBox(height: 6),
                const Text('Log in to your DesiredWash account',
                    style: TextStyle(fontSize: 15, color: AppColors.warmGray)),
                const SizedBox(height: 32),
                AuthField(
                    label: 'Email',
                    hint: 'jane@email.com',
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v?.contains('@') ?? false)
                        ? null
                        : 'Enter a valid email'),
                const SizedBox(height: 16),
                AuthField(
                  label: 'Password',
                  hint: '••••••••',
                  controller: _password,
                  obscure: _obscure,
                  suffix: IconButton(
                    icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.warmGray),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) =>
                      (v?.isNotEmpty ?? false) ? null : 'Enter your password',
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen())),
                    child: const Text('Forgot password?',
                        style: TextStyle(
                            color: AppColors.coral,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                if (auth.error != null) ...[
                  const SizedBox(height: 12),
                  AuthErrorBanner(auth.error!),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: auth.loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.coral,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      elevation: 0,
                    ),
                    child: auth.loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Log In',
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
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await context
        .read<AuthProvider>()
        .signInWithEmail(email: _email.text.trim(), password: _password.text);
    if (ok && mounted)
      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }
}
