import 'package:flutter/material.dart';

import 'package:survivor_pool/core/models/contestant.dart';
import 'package:survivor_pool/core/models/pick.dart';
import 'package:survivor_pool/core/models/pool.dart';

class PoolDashboard extends StatelessWidget {
  final PoolOption pool;
  final List<AvailableContestant> availableContestants;
  final bool isLoadingContestants;
  final CurrentPickSummary? currentPick;
  final VoidCallback? onManageMembers;
  final VoidCallback? onManageSettings;
  final VoidCallback? onAdvanceWeek;
  final void Function(AvailableContestant contestant)? onContestantSelected;

  const PoolDashboard({
    super.key,
    required this.pool,
    this.availableContestants = const [],
    this.isLoadingContestants = false,
    this.currentPick,
    this.onManageMembers,
    this.onManageSettings,
    this.onAdvanceWeek,
    this.onContestantSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final estimatedHeight = availableContestants.length * 76.0;
    final listHeight = availableContestants.isEmpty
        ? 160.0
        : estimatedHeight < 220.0
        ? 220.0
        : estimatedHeight > 420.0
        ? 420.0
        : estimatedHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderCard(theme),
        const SizedBox(height: 24),
        _buildWeeklyPickCard(theme, listHeight, currentPick),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHeaderCard(ThemeData theme) {
    final seasonDescription = pool.seasonNumber != null
        ? 'Season: ${pool.seasonNumber}'
        : pool.seasonId.isEmpty
        ? 'Season details coming soon'
        : 'Season: ${pool.seasonId}';

    final hasSettings = onManageSettings != null;
    final hasManageMembers = onManageMembers != null;
    final hasAdvance = onAdvanceWeek != null;

    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      pool.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (hasSettings) ...[
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: onManageSettings,
                      icon: const Icon(Icons.settings_outlined),
                      label: const Text('Pool settings'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                seasonDescription,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (hasManageMembers || hasAdvance) ...[
                const SizedBox(height: 24),
              ],
              if (hasManageMembers)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onManageMembers,
                    icon: const Icon(Icons.group_outlined),
                    label: const Text('Manage members'),
                  ),
                ),
              if (hasManageMembers && hasAdvance) const SizedBox(height: 16),
              if (hasAdvance)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: onAdvanceWeek,
                    icon: const Icon(Icons.skip_next_rounded),
                    label: const Text('Advance to next week'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyPickCard(
    ThemeData theme,
    double listHeight,
    CurrentPickSummary? currentPick,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "This Week's Pick",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Week ${pool.currentWeek}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              currentPick != null
                  ? 'Pick locked in for this week.'
                  : 'Choose a contestant below to review their details before locking your pick.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            if (currentPick != null)
              _buildLockedPickSummary(theme, currentPick)
            else
              SizedBox(height: listHeight, child: _buildContestantList(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildContestantList(ThemeData theme) {
    if (isLoadingContestants) {
      return const Center(child: CircularProgressIndicator());
    }

    if (availableContestants.isEmpty) {
      return Center(
        child: Text(
          'No available contestants yet. Check back after the next elimination.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Scrollbar(
      child: ListView.separated(
        itemCount: availableContestants.length,
        itemBuilder: (context, index) {
          final contestant = availableContestants[index];
          return FilledButton.tonal(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              final handler = onContestantSelected;
              if (handler != null) {
                handler(contestant);
              }
            },
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        contestant.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (contestant.subtitle != null &&
                          contestant.subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          contestant.subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          );
        },
        separatorBuilder: (_, index) => const SizedBox(height: 12),
      ),
    );
  }

  Widget _buildLockedPickSummary(ThemeData theme, CurrentPickSummary summary) {
    final handler = onContestantSelected;
    final lockedAt = summary.lockedAt.toLocal();
    final timestamp = _formatTimestamp(lockedAt);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  summary.contestantName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Locked at $timestamp',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: handler == null
                ? null
                : () {
                    handler(
                      AvailableContestant(
                        id: summary.contestantId,
                        name: summary.contestantName,
                      ),
                    );
                  },
            icon: const Icon(Icons.info_outline),
            label: const Text('View contestant details'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime value) {
    final year = value.year;
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$month/$day/$year $hour:$minute';
  }
}
