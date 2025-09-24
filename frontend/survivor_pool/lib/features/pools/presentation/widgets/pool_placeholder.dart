import 'package:flutter/material.dart';

import 'package:survivor_pool/core/models/pool.dart';

class PoolPlaceholder extends StatelessWidget {
  final PoolOption pool;

  const PoolPlaceholder({super.key, required this.pool});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pool.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.primaryColor.withAlpha(51)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pool dashboard coming soon for ${pool.name}.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  pool.seasonNumber != null
                      ? 'Season: ${pool.seasonNumber}'
                      : "Season: ${pool.seasonId.isEmpty ? 'TBD' : pool.seasonId}",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
