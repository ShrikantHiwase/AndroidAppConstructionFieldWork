import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../../../core/constants/app_constants.dart';

/// Temporary home until auth + role dashboards land in Phase 1.
class SplashHomePage extends StatelessWidget {
  const SplashHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ScaffoldShell(
      title: 'Field Evidence',
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Construction Field App', style: textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Phase 0 scaffold — Flutter + Firebase foundations. '
            'Auth, issues/RFIs, documents, and offline sync come in Phase 1.',
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Text('Primary actions (field UX)', style: textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.report_problem_outlined),
                label: const Text('New Issue'),
              ),
              FilledButton.tonalIcon(
                onPressed: () {},
                icon: const Icon(Icons.assignment_outlined),
                label: const Text("Today's DPR"),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.push_pin_outlined),
                label: const Text('Pin on Drawing'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text('Roles (RAYNS)', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          ...AppRole.values.map(
            (role) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline),
              title: Text(role.firestoreValue),
            ),
          ),
        ],
      ),
    );
  }
}
