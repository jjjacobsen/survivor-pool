import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:survivor_pool/app/routes.dart';
import 'package:survivor_pool/core/constants/api.dart';
import 'package:survivor_pool/core/constants/layout.dart';
import 'package:survivor_pool/core/layout/adaptive_page.dart';
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= AppBreakpoints.medium;
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: AdaptivePage(
                maxWidth: 720,
                compactPadding: const EdgeInsets.all(24),
                widePadding: const EdgeInsets.symmetric(
                  horizontal: 64,
                  vertical: 48,
                ),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(isWide ? 40 : 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account overview',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Manage your Survivor Pool profile and account preferences.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ...entries.expand(
                          (entry) => [
                            Text(
                              entry.label,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(entry.value, style: theme.textTheme.bodyLarge),
                            const SizedBox(height: 20),
                          ],
                        ),
                        if (_error != null) ...[
                          Text(
                            _error!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: isWide ? 220 : double.infinity,
                              child: FilledButton.icon(
                                onPressed: _isDeleting ? null : _confirmDelete,
                                style: FilledButton.styleFrom(
                                  backgroundColor: theme.colorScheme.error,
                                  foregroundColor: theme.colorScheme.onError,
                                ),
                                icon: const Icon(Icons.delete_outline),
                                label: Text(
                                  _isDeleting
                                      ? 'Deleting...'
                                      : 'Delete account',
                                ),
                              ),
                            ),
                            SizedBox(
                              width: isWide ? 220 : double.infinity,
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
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
