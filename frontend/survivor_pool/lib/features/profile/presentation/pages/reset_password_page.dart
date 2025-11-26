import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:survivor_pool/app/routes.dart';
import 'package:survivor_pool/core/constants/api.dart';
import 'package:survivor_pool/core/constants/layout.dart';
import 'package:survivor_pool/core/layout/adaptive_page.dart';
import 'package:survivor_pool/core/models/user.dart';
import 'package:survivor_pool/core/network/auth_client.dart';

class ResetPasswordPage extends StatefulWidget {
  final AppUser user;

  const ResetPasswordPage({super.key, required this.user});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final response = await AuthHttpClient.patch(
        Uri.parse('${ApiConfig.baseUrl}/users/${widget.user.id}/password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'current_password': _currentPasswordController.text,
          'new_password': _newPasswordController.text,
          'confirm_password': _confirmPasswordController.text,
        }),
      );

      if (response.statusCode == 204) {
        if (!mounted) {
          return;
        }
        await showDialog<void>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Password updated'),
              content: const Text('Sign in again with your new password.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        await AppSession.clear();
        if (mounted) {
          context.goNamed(AppRouteNames.login);
        }
        return;
      }

      if (mounted) {
        setState(() {
          _error = _parseError(response.body);
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = 'Unable to reset password: $error';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _parseError(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String && detail.isNotEmpty) {
          return detail;
        }
      }
    } catch (_) {}
    return 'Could not reset password. Try again.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset password'),
        automaticallyImplyLeading: true,
      ),
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reset password',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter your current password and set a new one.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _currentPasswordController,
                            decoration: const InputDecoration(
                              labelText: 'Current password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter your current password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _newPasswordController,
                            decoration: const InputDecoration(
                              labelText: 'New password',
                              prefixIcon: Icon(Icons.lock),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter a new password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: const InputDecoration(
                              labelText: 'Confirm new password',
                              prefixIcon: Icon(Icons.lock_reset),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Confirm your new password';
                              }
                              if (value != _newPasswordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          if (_error != null) ...[
                            Text(
                              _error!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          FilledButton.icon(
                            onPressed: _isSubmitting ? null : _submit,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.check_circle_outline),
                            label: Text(
                              _isSubmitting ? 'Updating...' : 'Update password',
                            ),
                          ),
                        ],
                      ),
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
