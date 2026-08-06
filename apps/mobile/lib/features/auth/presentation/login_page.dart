import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController(text: 'engineer@demo.rayns');
  final _password = TextEditingController(text: 'demo1234');
  final _formKey = GlobalKey<FormState>();

  static const _demoHints = [
    'engineer@demo.rayns',
    'pm@demo.rayns',
    'qa@demo.rayns',
    'client@demo.rayns',
    'admin@demo.rayns',
  ];

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(authControllerProvider.notifier).signIn(
          email: _email.text,
          password: _password.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final firebaseEnabled = ref.watch(firebaseEnabledProvider);
    final textTheme = Theme.of(context).textTheme;
    final busy = auth.isSubmitting;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),
            Text('Field Evidence', style: textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text(
              firebaseEnabled
                  ? 'Sign in with your org email (Firebase Auth).'
                  : 'Demo mode — password for all accounts: demo1234',
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              firebaseEnabled ? 'Backend: Firebase' : 'Backend: local demo',
              style: textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Email required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Password required' : null,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                ],
              ),
            ),
            if (auth.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                auth.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: busy ? null : _submit,
              child: busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sign in'),
            ),
            if (!firebaseEnabled) ...[
              const SizedBox(height: 32),
              Text('Demo roles', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _demoHints
                    .map(
                      (email) => ActionChip(
                        label: Text(email.split('@').first),
                        onPressed: () {
                          _email.text = email;
                          _password.text = 'demo1234';
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
