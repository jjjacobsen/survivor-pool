import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:survivor_pool/core/constants/api.dart';
import 'package:survivor_pool/core/models/pool.dart';
import 'package:survivor_pool/core/widgets/confirmation_dialog.dart';

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
      final response = await http.delete(
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
      appBar: AppBar(title: Text('Pool settings — ${pool.name}')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pool details',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(theme, label: 'Pool name', value: pool.name),
                    _buildInfoRow(theme, label: 'Season', value: seasonValue),
                    _buildInfoRow(
                      theme,
                      label: 'Current week',
                      value: pool.currentWeek.toString(),
                    ),
                  ],
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isDeleting ? null : _confirmDelete,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              icon: const Icon(Icons.delete_outline),
              label: Text(_isDeleting ? 'Deleting...' : 'Delete pool'),
            ),
          ],
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
