import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:survivor_pool/app/routes.dart';
import 'package:survivor_pool/core/constants/api.dart';
import 'package:survivor_pool/core/models/user.dart';
import 'package:survivor_pool/core/widgets/confirmation_dialog.dart';

class ProfilePage extends StatefulWidget {
  final AppUser user;

  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isDeleting = false;
  String? _error;

  void _logout() {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  Future<void> _confirmDelete() async {
    if (_isDeleting) {
      return;
    }

    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Delete account',
      message:
          'Are you sure you want to delete your account? All of your pools, memberships, and picks will be removed.',
      confirmLabel: 'Delete',
    );

    if (!mounted || !confirmed) {
      return;
    }

    await _deleteUser();
  }

  Future<void> _deleteUser() async {
    setState(() {
      _isDeleting = true;
      _error = null;
    });

    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/users/${widget.user.id}'),
      );

      if (response.statusCode == 204) {
        if (mounted) {
          _logout();
        }
        return;
      }

      final message = _parseError(response.body, 'Unable to delete account.');
      if (mounted) {
        setState(() {
          _error = message;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = 'Network error: $error';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  String _parseError(String body, String fallback) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String && detail.isNotEmpty) {
          return detail;
        }
      }
    } catch (_) {
      // Ignore parsing failures.
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = <({String label, String value})>[
      (label: 'Display name', value: widget.user.displayName),
      (label: 'Username', value: '@${widget.user.username}'),
      (label: 'Email', value: widget.user.email),
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
            if (_error != null) ...[
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isDeleting ? null : _confirmDelete,
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(_isDeleting ? 'Deleting...' : 'Delete account'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isDeleting ? null : _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
