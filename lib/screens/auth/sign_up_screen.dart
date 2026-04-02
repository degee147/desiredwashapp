import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../zone/zone_picker_screen.dart';
import 'auth_widgets.dart';

// ─── SIGN UP SCREEN ───────────────────────────────────────────────────────────

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _agreed = false;

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
                const Text('Create account',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText)),
                const SizedBox(height: 6),
                const Text('Get started with DesiredWash 🫧',
                    style: TextStyle(fontSize: 15, color: AppColors.warmGray)),
                const SizedBox(height: 32),
                AuthField(
                    label: 'Full Name',
                    hint: 'Jane Doe',
                    controller: _name,
                    validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? 'Enter your name' : null),
                const SizedBox(height: 16),
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
                    label: 'Phone (optional)',
                    hint: '08012345678',
                    controller: _phone,
                    keyboardType: TextInputType.phone),
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
                      (v?.length ?? 0) < 8 ? 'Min. 8 characters' : null,
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreed,
                      activeColor: AppColors.coral,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      onChanged: (v) => setState(() => _agreed = v ?? false),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                                fontSize: 13, color: AppColors.warmGray),
                            children: [
                              TextSpan(text: 'I agree to the '),
                              TextSpan(
                                  text: 'Terms of Service',
                                  style: TextStyle(
                                      color: AppColors.coral,
                                      fontWeight: FontWeight.w600)),
                              TextSpan(text: ' and '),
                              TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                      color: AppColors.coral,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (auth.error != null) ...[
                  const SizedBox(height: 12),
                  AuthErrorBanner(auth.error!),
                ],
                const SizedBox(height: 24),
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
                        : const Text('Create Account',
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
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please accept the Terms to continue')));
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.signUpWithEmail(
      name: _name.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
    );
    if (ok && mounted) {
      await Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ZonePickerScreen()));
      if (mounted)
        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    }
  }
}
