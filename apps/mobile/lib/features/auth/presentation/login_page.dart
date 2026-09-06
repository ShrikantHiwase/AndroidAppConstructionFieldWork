import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_locale_provider.dart';
import '../../../l10n/app_localizations.dart';
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
  var _obscurePassword = true;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

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
          email: _email.text.trim(),
          password: _password.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final firebaseEnabled = ref.watch(firebaseEnabledProvider);
    final localeOverride = ref.watch(appLocaleProvider);
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final busy = auth.isSubmitting;
    final selectedLang = localeOverride?.languageCode ?? 'en';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),
            Text(l10n.appTitle, style: textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text(
              firebaseEnabled ? l10n.firebaseSignInHint : l10n.demoModeHint,
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              firebaseEnabled ? l10n.backendFirebase : l10n.backendLocalDemo,
              style: textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.languagePickerLabel, style: textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'en',
                  label: Text(l10n.languageEnglish),
                ),
                ButtonSegment(
                  value: 'hi',
                  label: Text(l10n.languageHinglish),
                ),
              ],
              selected: {selectedLang == 'hi' ? 'hi' : 'en'},
              onSelectionChanged: (next) {
                ref.read(appLocaleProvider.notifier).setLocaleCode(next.first);
              },
            ),
            const SizedBox(height: 32),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(
                      labelText: l10n.emailLabel,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return l10n.emailRequired;
                      if (!_emailPattern.hasMatch(value)) {
                        return l10n.emailInvalid;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: l10n.passwordLabel,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? l10n.showPassword
                            : l10n.hidePassword,
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? l10n.passwordRequired : null,
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
                  : Text(l10n.signIn),
            ),
            if (!firebaseEnabled) ...[
              const SizedBox(height: 32),
              Text(l10n.demoRoles, style: textTheme.titleMedium),
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
