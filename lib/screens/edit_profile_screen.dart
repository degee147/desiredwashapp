import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _addressCtrl = TextEditingController(text: user?.address ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final updated = await context.read<ApiService>().updateProfile(
            name: _nameCtrl.text.trim(),
            phone:
                _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
            address: _addressCtrl.text.trim().isEmpty
                ? null
                : _addressCtrl.text.trim(),
          );

      if (!mounted) return;

      context.read<AuthProvider>().updateLocalUser(updated);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D60),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Profile updated successfully',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ],
            ),
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('ApiException', '').trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Profile',
            style: TextStyle(
                color: AppColors.darkText,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: AppColors.coral, strokeWidth: 2.2))
                  : const Text('Save',
                      style: TextStyle(
                          color: AppColors.coral,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar placeholder ──────────────────────────────────────────
              Center(
                child: _AvatarSection(
                    name: _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'U'),
              ),
              const SizedBox(height: 32),

              // ── Error banner ────────────────────────────────────────────────
              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: Colors.red.shade400, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(_error!,
                              style: TextStyle(
                                  color: Colors.red.shade700, fontSize: 13))),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── Fields ──────────────────────────────────────────────────────
              _SectionLabel('Personal Info'),
              const SizedBox(height: 12),

              _FieldCard(
                children: [
                  _Field(
                    controller: _nameCtrl,
                    label: 'Full Name',
                    icon: Icons.person_rounded,
                    hint: 'Enter your full name',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Name is required';
                      }
                      if (v.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}), // rebuild avatar
                  ),
                  _Divider(),
                  _Field(
                    controller: _phoneCtrl,
                    label: 'Phone Number',
                    icon: Icons.phone_rounded,
                    hint: 'e.g. 08012345678',
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final digits = v.trim().replaceAll(RegExp(r'\D'), '');
                      if (digits.length < 10) {
                        return 'Enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _SectionLabel('Delivery Address'),
              const SizedBox(height: 12),

              _FieldCard(
                children: [
                  _Field(
                    controller: _addressCtrl,
                    label: 'Address',
                    icon: Icons.home_rounded,
                    hint: 'Enter your pickup/delivery address',
                    maxLines: 3,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Save button ─────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.coral,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text('Save Changes',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── AVATAR SECTION ───────────────────────────────────────────────────────────

class _AvatarSection extends StatelessWidget {
  final String name;
  const _AvatarSection({required this.name});

  String get _initials {
    final parts = name.trim().split(' ').where((w) => w.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: const BoxDecoration(
        color: AppColors.lavender,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(_initials,
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF7B5EA7),
                fontSize: 30)),
      ),
    );
  }
}

// ─── HELPERS ─────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.warmGray,
          letterSpacing: 0.5));
}

class _FieldCard extends StatelessWidget {
  final List<Widget> children;
  const _FieldCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(children: children),
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, color: Colors.grey.shade100, indent: 52);
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 16 : 14),
            child: Icon(icon, size: 20, color: AppColors.coral),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              onChanged: onChanged,
              validator: validator,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(
                    fontSize: 12,
                    color: AppColors.warmGray,
                    fontWeight: FontWeight.w500),
                hintText: hint,
                hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                    fontWeight: FontWeight.w400),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                errorStyle: const TextStyle(fontSize: 11, height: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
