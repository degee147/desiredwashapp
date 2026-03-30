import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../zone/zone_picker_screen.dart';

// ─── WELCOME SCREEN ───────────────────────────────────────────────────────────

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.cream, AppColors.bg, Color(0xFFE8F4F8)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.coral.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8))
                    ],
                  ),
                  child: const Icon(Icons.local_laundry_service_rounded,
                      color: AppColors.coral, size: 38),
                ),
                const SizedBox(height: 28),
                const Text('Laundry done\nfor you. 🫧',
                    style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText,
                        height: 1.1)),
                const SizedBox(height: 14),
                const Text(
                    'Schedule a pickup in minutes. We wash,\ndry & deliver in Port Harcourt.',
                    style: TextStyle(
                        fontSize: 16, color: AppColors.warmGray, height: 1.5)),
                const Spacer(flex: 2),
                _SocialButton(
                  label: 'Continue with Google',
                  icon: Icons.g_mobiledata_rounded,
                  onTap: () => _handleGoogle(context),
                ),
                const SizedBox(height: 12),
                _SocialButton(
                  label: 'Continue with Apple',
                  icon: Icons.apple_rounded,
                  onTap: () => _handleApple(context),
                  dark: true,
                ),
                const SizedBox(height: 20),
                const Row(children: [
                  Expanded(child: Divider(color: AppColors.cream)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child:
                        Text('or', style: TextStyle(color: AppColors.warmGray)),
                  ),
                  Expanded(child: Divider(color: AppColors.cream)),
                ]),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SignUpScreen())),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.coral,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Sign up with Email',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: RichText(
                      text: const TextSpan(
                        style:
                            TextStyle(fontSize: 15, color: AppColors.warmGray),
                        children: [
                          TextSpan(text: 'Already have an account? '),
                          TextSpan(
                              text: 'Log in',
                              style: TextStyle(
                                  color: AppColors.coral,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleGoogle(BuildContext context) async {
    // TODO: Add google_sign_in package and uncomment:
    // final googleUser = await GoogleSignIn().signIn();
    // final auth = await googleUser?.authentication;
    // if (auth?.idToken == null) return;
    // await context.read<AuthProvider>().signInWithGoogle(auth!.idToken!, ...);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add google_sign_in package to enable')));
  }

  void _handleApple(BuildContext context) async {
    // TODO: Add sign_in_with_apple package and uncomment
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Add sign_in_with_apple package to enable')));
  }
}

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
                _Field(
                    label: 'Full Name',
                    hint: 'Jane Doe',
                    controller: _name,
                    validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? 'Enter your name' : null),
                const SizedBox(height: 16),
                _Field(
                    label: 'Email',
                    hint: 'jane@email.com',
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v?.contains('@') ?? false)
                        ? null
                        : 'Enter a valid email'),
                const SizedBox(height: 16),
                _Field(
                    label: 'Phone (optional)',
                    hint: '08012345678',
                    controller: _phone,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                _Field(
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
                  _ErrorBanner(auth.error!),
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
      final zone = await Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ZonePickerScreen()));
      if (mounted)
        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    }
  }
}

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
                _Field(
                    label: 'Email',
                    hint: 'jane@email.com',
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v?.contains('@') ?? false)
                        ? null
                        : 'Enter a valid email'),
                const SizedBox(height: 16),
                _Field(
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
                  _ErrorBanner(auth.error!),
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

// ─── FORGOT PASSWORD ──────────────────────────────────────────────────────────

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
                    _Field(
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

// ─── SHARED FIELD WIDGET ─────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscure;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
    this.suffix,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscure,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppColors.warmGray.withOpacity(0.6)),
              suffixIcon: suffix,
              filled: true,
              fillColor: AppColors.cardBg,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.coral, width: 1.5)),
              errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.red)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
            const SizedBox(width: 8),
            Expanded(
                child: Text(message,
                    style:
                        TextStyle(color: Colors.red.shade700, fontSize: 13))),
          ],
        ),
      );
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool dark;
  const _SocialButton(
      {required this.label,
      required this.icon,
      required this.onTap,
      this.dark = false});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            backgroundColor: dark ? Colors.black : AppColors.cardBg,
            side: BorderSide(color: dark ? Colors.black : AppColors.cream),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: dark ? Colors.white : AppColors.darkText, size: 22),
              const SizedBox(width: 10),
              Text(label,
                  style: TextStyle(
                      color: dark ? Colors.white : AppColors.darkText,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
            ],
          ),
        ),
      );
}
