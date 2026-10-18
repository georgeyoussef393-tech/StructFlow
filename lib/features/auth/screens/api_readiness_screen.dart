import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../repositories/auth_repository.dart';

class ApiReadinessScreen extends StatefulWidget {
  const ApiReadinessScreen({super.key});

  @override
  State<ApiReadinessScreen> createState() => _ApiReadinessScreenState();
}

class _ApiReadinessScreenState extends State<ApiReadinessScreen> {
  bool _signingOut = false;
  String? _signOutError;

  Future<void> _signOut() async {
    setState(() {
      _signingOut = true;
      _signOutError = null;
    });
    try {
      await AuthRepository.instance.signOut();
    } on Exception catch (error) {
      if (mounted) setState(() => _signOutError = error.toString());
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthRepository.instance.currentUser;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_user_outlined, size: 56),
                const SizedBox(height: 16),
                const Text(
                  'تم التحقق من الحساب، ويمكنك استعراض وإنشاء المشاريع حسب '
                  'صلاحيتك.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Signed in as ${user?.email ?? 'user'}${user == null ? '' : ' · ${user.organization}'}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Authentication, company project listing, and project '
                  'creation use the API. '
                  'Project details, tasks, documents, '
                  'workforce, and attendance are not yet migrated to '
                  'tenant-scoped APIs, so demo data stays blocked.',
                  textAlign: TextAlign.center,
                ),
                if (_signOutError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'The local session was cleared, but the server revoke '
                    'request failed: $_signOutError',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _signingOut ? null : _signOut,
                  icon: _signingOut
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
                if (user != null)
                  TextButton.icon(
                    onPressed: () => context.go('/projects'),
                    icon: const Icon(Icons.folder_outlined),
                    label: const Text('View company projects'),
                  ),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Return to sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
