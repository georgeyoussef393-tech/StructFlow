import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../attendance/models/attendance_context_model.dart';
import '../../attendance/models/attendance_permission_model.dart';
import '../../attendance/repositories/attendance_context_repository.dart';
import '../../attendance/repositories/attendance_permission_repository.dart';
import '../repositories/auth_repository.dart';

class OwnerSetupScreen extends StatefulWidget {
  const OwnerSetupScreen({super.key});

  @override
  State<OwnerSetupScreen> createState() => _OwnerSetupScreenState();
}

class _OwnerSetupScreenState extends State<OwnerSetupScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final organization = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  bool obscure = true;
  bool loading = false;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    organization.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> _setup() async {
    if ([
      name,
      email,
      organization,
      password,
      confirm,
    ].any((c) => c.text.trim().isEmpty)) {
      _message('Complete all required fields.');
      return;
    }
    if (password.text != confirm.text) {
      _message('Passwords do not match.');
      return;
    }

    setState(() => loading = true);
    final error = await AuthRepository.instance.setupOwner(
      name: name.text,
      email: email.text,
      password: password.text,
      organization: organization.text,
    );
    if (!mounted) return;
    setState(() => loading = false);

    if (error != null) {
      _message(error);
      return;
    }
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
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: () => context.go('/login'),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'StructFlow Owner Setup',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create the single System Owner account. This account has full control over StructFlow.',
                        style: TextStyle(color: AppColors.textLight),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: name,
                        decoration: const InputDecoration(
                          labelText: 'Owner name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Owner email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: organization,
                        decoration: const InputDecoration(
                          labelText: 'StructFlow organization',
                          prefixIcon: Icon(Icons.business_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: password,
                        obscureText: obscure,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => obscure = !obscure),
                            icon: Icon(
                              obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: confirm,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm password',
                          prefixIcon: Icon(Icons.lock_reset_outlined),
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: loading ? null : _setup,
                          child: loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Create System Owner'),
                        ),
                      ),
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
