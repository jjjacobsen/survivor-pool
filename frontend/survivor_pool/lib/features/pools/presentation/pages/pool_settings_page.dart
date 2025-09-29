import 'package:flutter/material.dart';

import 'package:survivor_pool/core/models/pool.dart';

class PoolSettingsPage extends StatelessWidget {
  final PoolOption pool;

  const PoolSettingsPage({super.key, required this.pool});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
