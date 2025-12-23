import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_service.dart';
import '../main.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              TextField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: 'Password (min 6)')),
              if (_error != null) Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : () async {
                  setState(() { _busy = true; _error = null; });
                  final svc = ref.read(authServiceProvider);
                  final err = await svc.login(_email.text, _pass.text);
                  setState(() { _busy = false; _error = err; });
                  if (err == null && mounted) context.go('/');
                },
                child: _busy ? const CircularProgressIndicator() : const Text('Login'),
              ),
              TextButton(
                onPressed: () => context.go('/register'),
                child: const Text("New user? Register"),
              )
            ]),
          ),
        ),
      ),
    );
  }
}
