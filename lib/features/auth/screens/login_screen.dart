import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../attendance/models/attendance_context_model.dart';
import '../../attendance/models/attendance_permission_model.dart';
import '../../attendance/repositories/attendance_context_repository.dart';
import '../../attendance/repositories/attendance_permission_repository.dart';
import '../repositories/auth_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();

  bool loading = false;
  bool obscure = true;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      _message('Enter email and password.');
      return;
    }

    setState(() => loading = true);

    String? error;
    try {
      error = await AuthRepository.instance.signIn(
        email: email.text.trim(),
        password: password.text,
      );
    } on Exception {
      if (!mounted) return;
      setState(() => loading = false);
      _message(
        'Sign in could not be completed. Check the server configuration and '
        'secure storage, then try again.',
      );
      return;
    }

    if (!mounted) return;

    setState(() => loading = false);

    if (error != null) {
      _message(error);
      return;
    }

    if (AuthRepository.instance.usesApiAuth) return;

    final user = AuthRepository.instance.currentUser!;
    if (user.isOwner) {
      final organizationId =
          'ORG-${user.organization.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}';
      await AttendancePermissionRepository.instance.seedSuperAdmin(
        AttendancePermissionModel.owner(
          id: 'PERM-${user.id}',
          organizationId: organizationId,
          userId: user.id,
        ),
      );
    }
    await AttendanceContextRepository.instance.save(
      AttendanceContextModel(
        organizationId:
            'ORG-${user.organization.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}',
        userId: user.id,
      ),
    );
    if (!mounted) return;
    context.go('/');
  }

  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.account_tree_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Center(
                        child: Text(
                          'Welcome to StructFlow',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'Construction Project Management System',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textLight),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'Sign in',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: password,
                        obscureText: obscure,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() => obscure = !obscure);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: loading ? null : _login,
                          child: loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Sign In'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (!AuthRepository.instance.usesApiAuth &&
                          !AuthRepository.instance.hasOwner)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => context.go('/owner-setup'),
                            icon: const Icon(
                              Icons.admin_panel_settings_outlined,
                            ),
                            label: const Text(
                              'First-time StructFlow Owner Setup',
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      if (!AuthRepository.instance.usesApiAuth)
                        Center(
                          child: TextButton(
                            onPressed: () => context.go('/register'),
                            child: const Text(
                              "Don't have an account? Create one",
                            ),
                          ),
                        ),
                      if (AuthRepository.instance.usesApiAuth) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Accounts must be provisioned by your company '
                          'administrator. Local demo registration is disabled.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textLight),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
