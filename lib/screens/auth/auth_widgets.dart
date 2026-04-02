import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

// ─── SHARED FIELD WIDGET ─────────────────────────────────────────────────────

class AuthField extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscure;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const AuthField({
    super.key,
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

class AuthErrorBanner extends StatelessWidget {
  final String message;
  const AuthErrorBanner(this.message, {super.key});

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

class AuthSocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool dark;
  const AuthSocialButton(
      {super.key,
      required this.label,
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
