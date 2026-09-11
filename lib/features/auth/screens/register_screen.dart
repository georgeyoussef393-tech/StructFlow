import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../repositories/auth_repository.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController(); final email = TextEditingController(); final org = TextEditingController(); final password = TextEditingController(); final confirm = TextEditingController();
  String role = 'Contracting Company'; bool loading = false; bool obscure = true;
  static const roles = ['Contracting Company', 'Consultant', 'Freelance Engineer', 'Client'];
  @override void dispose() { name.dispose(); email.dispose(); org.dispose(); password.dispose(); confirm.dispose(); super.dispose(); }

  Future<void> _register() async {
    if ([name,email,org,password,confirm].any((c) => c.text.trim().isEmpty)) { _message('Complete all required fields.'); return; }
    if (password.text != confirm.text) { _message('Passwords do not match.'); return; }
    setState(() => loading = true);
    final error = await AuthRepository.instance.register(name: name.text, email: email.text, password: password.text, role: role, organization: org.text);
    if (!mounted) return; setState(() => loading = false);
    if (error != null) { _message(error); return; }
    context.go('/');
  }
  void _message(String text) => ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content: Text(text)));

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: Card(child: Padding(padding: const EdgeInsets.all(30), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [IconButton(onPressed: () => context.go('/login'), icon: const Icon(Icons.arrow_back_rounded)), const Spacer(), const Text('StructFlow', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)), const Spacer(), const SizedBox(width: 48)]),
      const SizedBox(height: 18), const Text('Create your StructFlow account', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800)), const SizedBox(height: 7), const Text('Start with the account type that matches your business.', style: TextStyle(color: AppColors.textLight)), const SizedBox(height: 24),
      TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline))), const SizedBox(height: 12),
      TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))), const SizedBox(height: 12),
      TextField(controller: org, decoration: const InputDecoration(labelText: 'Company / Organization', prefixIcon: Icon(Icons.business_outlined))), const SizedBox(height: 12),
      DropdownButtonFormField<String>(initialValue: role, decoration: const InputDecoration(labelText: 'Account type', prefixIcon: Icon(Icons.badge_outlined)), items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(), onChanged: (v) => setState(() => role = v ?? roles.first)), const SizedBox(height: 12),
      TextField(controller: password, obscureText: obscure, decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(onPressed: () => setState(() => obscure = !obscure), icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined)))), const SizedBox(height: 12),
      TextField(controller: confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm password', prefixIcon: Icon(Icons.lock_reset_outlined))), const SizedBox(height: 22),
      SizedBox(width: double.infinity, height: 50, child: FilledButton(onPressed: loading ? null : _register, child: loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Create Account'))), const SizedBox(height: 10),
      Center(child: TextButton(onPressed: () => context.go('/login'), child: const Text('Already have an account? Sign in'))),
    ]))))))),
  );
}
