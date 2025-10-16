import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:survivor_pool/core/constants/api.dart';
import 'package:survivor_pool/core/constants/layout.dart';
import 'package:survivor_pool/core/models/pool.dart';
import 'package:survivor_pool/core/widgets/confirmation_dialog.dart';
import 'package:survivor_pool/core/layout/adaptive_page.dart';
import 'package:survivor_pool/core/network/auth_client.dart';

class PoolSettingsPage extends StatefulWidget {
  final PoolOption pool;
  final String ownerId;

  const PoolSettingsPage({
    super.key,
    required this.pool,
    required this.ownerId,
  });

  @override
  State<PoolSettingsPage> createState() => _PoolSettingsPageState();
}

class _PoolSettingsPageState extends State<PoolSettingsPage> {
  bool _isDeleting = false;
  String? _error;

  Future<void> _confirmDelete() async {
    if (_isDeleting) {
      return;
    }

    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Delete pool',
      message:
          'Are you sure you want to delete this pool? All memberships and picks will be removed.',
      confirmLabel: 'Delete',
    );

    if (!mounted || !confirmed) {
      return;
    }

    await _deletePool();
  }

  Future<void> _deletePool() async {
    setState(() {
      _isDeleting = true;
      _error = null;
    });

    try {
      final response = await AuthHttpClient.delete(
        Uri.parse(
          '${ApiConfig.baseUrl}/pools/${widget.pool.id}?owner_id=${widget.ownerId}',
        ),
      );

      if (response.statusCode == 204) {
        if (mounted) {
          Navigator.of(
            context,
          ).pop({'deleted': true, 'poolId': widget.pool.id});
        }
        return;
      }

      final message = _parseError(response.body, 'Unable to delete pool.');
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
    final pool = widget.pool;
    final seasonValue = pool.seasonNumber != null
        ? 'Season ${pool.seasonNumber}'
        : pool.seasonId.isEmpty
        ? 'Season not linked yet'
        : pool.seasonId;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pool settings — ${pool.name}'),
        automaticallyImplyLeading: !kIsWeb,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pool overview',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Manage settings and lifecycle actions for ${pool.name}.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildInfoRow(
                          theme,
                          label: 'Pool name',
                          value: pool.name,
                        ),
                        _buildInfoRow(
                          theme,
                          label: 'Season',
                          value: seasonValue,
                        ),
                        _buildInfoRow(
                          theme,
                          label: 'Start week',
                          value: pool.startWeek.toString(),
                        ),
                        _buildInfoRow(
                          theme,
                          label: 'Current week',
                          value: pool.currentWeek.toString(),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 24),
                          Text(
                            _error!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: isWide ? 240 : double.infinity,
                            child: FilledButton.icon(
                              onPressed: _isDeleting ? null : _confirmDelete,
                              style: FilledButton.styleFrom(
                                backgroundColor: theme.colorScheme.error,
                                foregroundColor: theme.colorScheme.onError,
                              ),
                              icon: const Icon(Icons.delete_outline),
                              label: Text(
                                _isDeleting ? 'Deleting...' : 'Delete pool',
                              ),
                            ),
                          ),
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

  Widget _buildInfoRow(
    ThemeData theme, {
    required String label,
    required String value,
  }) {
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
    );
    final valueStyle = theme.textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(height: 4),
          SelectableText(value, style: valueStyle),
        ],
      ),
    );
  }
}
