import 'package:flutter/material.dart';

import 'package:survivor_pool/app/routes.dart';
import 'package:survivor_pool/core/models/user.dart';

class ProfilePage extends StatelessWidget {
  final AppUser user;

  const ProfilePage({super.key, required this.user});

  void _logout(BuildContext context) {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = <({String label, String value})>[
      (label: 'Display name', value: user.displayName),
      (label: 'Username', value: '@${user.username}'),
      (label: 'Email', value: user.email),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final entry in entries) ...[
              Text(
                entry.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(entry.value, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 16),
            ],
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
