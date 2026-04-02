import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'auth_widgets.dart';
import 'sign_up_screen.dart';
import 'login_screen.dart';

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
                AuthSocialButton(
                  label: 'Continue with Google',
                  icon: Icons.g_mobiledata_rounded,
                  onTap: () => _handleGoogle(context),
                ),
                const SizedBox(height: 12),
                AuthSocialButton(
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
