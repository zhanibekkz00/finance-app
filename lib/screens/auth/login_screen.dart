import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app.dart';
import '../../providers/auth_provider.dart';
import 'package:finance_app/l10n/generated/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.login)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
                controller: _emailCtrl,
                decoration: InputDecoration(labelText: l10n.email)),
            TextField(
                controller: _passCtrl,
                decoration: InputDecoration(labelText: l10n.password),
                obscureText: true),
            const SizedBox(height: 20),
            auth.status == AuthStatus.loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () async {
                      final success = await ref
                          .read(authProvider.notifier)
                          .login(_emailCtrl.text, _passCtrl.text);
                      if (success && mounted) {
                        Navigator.pushReplacementNamed(P
                            context, AppRoutes.dashboard);
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Login failed')),
                        );
                      }
                    },
                    child: Text(l10n.login),
                  ),
          ],
        ),
      ),
    );
  }
}
