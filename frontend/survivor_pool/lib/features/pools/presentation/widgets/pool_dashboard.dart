import 'package:flutter/material.dart';

import 'package:survivor_pool/core/models/contestant.dart';
import 'package:survivor_pool/core/models/pick.dart';
import 'package:survivor_pool/core/models/pool.dart';

class PoolDashboard extends StatelessWidget {
  final PoolOption pool;
  final List<AvailableContestant> availableContestants;
  final bool isLoadingContestants;
  final CurrentPickSummary? currentPick;
  final int? score;
  final bool isEliminated;
  final String? eliminationReason;
  final int? eliminatedWeek;
  final bool isWinner;
  final String poolStatus;
  final int? poolCompletedWeek;
  final DateTime? poolCompletedAt;
  final List<PoolWinner> winners;
  final bool didTie;
  final VoidCallback? onManageMembers;
  final VoidCallback? onManageSettings;
  final VoidCallback? onAdvanceWeek;
  final VoidCallback? onViewLeaderboard;
  final void Function(AvailableContestant contestant)? onContestantSelected;

  const PoolDashboard({
    super.key,
    required this.pool,
    this.availableContestants = const [],
    this.isLoadingContestants = false,
    this.currentPick,
    this.score,
    this.isEliminated = false,
    this.eliminationReason,
    this.eliminatedWeek,
    this.isWinner = false,
    this.poolStatus = 'open',
    this.poolCompletedWeek,
    this.poolCompletedAt,
    this.winners = const [],
    this.didTie = false,
    this.onManageMembers,
    this.onManageSettings,
    this.onAdvanceWeek,
    this.onViewLeaderboard,
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
        _buildWeeklyPickCard(
          theme,
          listHeight,
          currentPick,
          isEliminated,
          eliminationReason,
          eliminatedWeek,
        ),
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
    final scoreText = score != null ? 'Remaining choices: ${score!}' : null;
    final poolCompleted = poolStatus == 'completed';
    final completionLabel = poolCompletedWeek != null
        ? 'Completed in week $poolCompletedWeek'
        : 'Pool completed';

    final hasSettings = onManageSettings != null;
    final hasManageMembers = onManageMembers != null;
    final hasAdvance = onAdvanceWeek != null;
    final hasLeaderboard = onViewLeaderboard != null;

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
              const SizedBox(height: 6),
              if (scoreText != null) ...[
                Text(
                  scoreText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isEliminated
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                'Week ${pool.currentWeek}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (poolCompleted) ...[
                const SizedBox(height: 6),
                Text(
                  completionLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (poolCompletedAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Completed on ${_formatTimestamp(poolCompletedAt!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
              if (hasLeaderboard) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: onViewLeaderboard,
                    icon: const Icon(Icons.leaderboard_outlined),
                    label: const Text('View leaderboard'),
                  ),
                ),
              ],
              if (hasManageMembers || hasAdvance) ...[
                const SizedBox(height: 16),
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
                    icon: const Icon(Icons.arrow_forward_rounded),
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
    bool isEliminated,
    String? eliminationReason,
    int? eliminatedWeek,
  ) {
    final poolCompleted = poolStatus == 'completed';
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              poolCompleted ? 'Pool Status' : "This Week's Pick",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (isWinner) ...[
              _buildWinnerMessage(theme),
            ] else if (isEliminated) ...[
              _buildEliminatedMessage(theme, eliminationReason, eliminatedWeek),
              if (poolCompleted && winners.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildWinnerList(theme),
              ],
            ] else if (poolCompleted) ...[
              _buildPoolCompletedMessage(theme),
              if (winners.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildWinnerList(theme),
              ],
            ] else ...[
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
                SizedBox(
                  height: listHeight,
                  child: _buildContestantList(theme),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEliminatedMessage(
    ThemeData theme,
    String? eliminationReason,
    int? eliminatedWeek,
  ) {
    final reasonText = _describeEliminationReason(eliminationReason);
    final weekDetail = eliminatedWeek != null
        ? 'Eliminated in week $eliminatedWeek.'
        : null;

    final details = <String>[];
    if (reasonText.isNotEmpty) {
      details.add(reasonText);
    }
    if (weekDetail != null) {
      details.add(weekDetail);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'The tribe has spoken.',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (details.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            details.join(' '),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWinnerMessage(ThemeData theme) {
    final lines = <String>[];
    if (poolCompletedWeek != null) {
      lines.add('Final week: $poolCompletedWeek.');
    }
    if (poolCompletedAt != null) {
      lines.add('Completed on ${_formatTimestamp(poolCompletedAt!)}.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          didTie
              ? 'You tied for the win!'
              : 'Congratulations, you won the pool!',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (lines.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            lines.join(' '),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (winners.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildWinnerList(theme),
        ],
      ],
    );
  }

  Widget _buildPoolCompletedMessage(ThemeData theme) {
    final lines = <String>[];
    if (poolCompletedWeek != null) {
      lines.add('Final week: $poolCompletedWeek.');
    }
    if (poolCompletedAt != null) {
      lines.add('Completed on ${_formatTimestamp(poolCompletedAt!)}.');
    }

    final headline = winners.isNotEmpty
        ? (didTie ? 'The pool ended in a tie.' : 'The pool has a winner.')
        : 'The pool has wrapped up.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          headline,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          lines.isNotEmpty ? lines.join(' ') : 'No further picks are required.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildWinnerList(ThemeData theme) {
    if (winners.isEmpty) {
      return const SizedBox.shrink();
    }

    final label = didTie ? 'Winners' : 'Winner';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < winners.length; i++) ...[
          Text(winners[i].displayName, style: theme.textTheme.bodyMedium),
          if (i < winners.length - 1) const SizedBox(height: 6),
        ],
      ],
    );
  }

  String _describeEliminationReason(String? reason) {
    switch (reason) {
      case 'missed_pick':
        return 'You missed your pick.';
      case 'contestant_voted_out':
        return 'Your pick was voted out.';
      case 'no_options_left':
        return 'You ran out of contestants to choose from.';
      default:
        return '';
    }
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

    final groups = _groupContestantsByTribe(availableContestants);
    final children = <Widget>[];

    for (var groupIndex = 0; groupIndex < groups.length; groupIndex++) {
      final group = groups[groupIndex];
      final headerColor =
          _parseColorHex(group.colorHex) ?? theme.colorScheme.primary;

      children.add(
        Text(
          group.label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: headerColor,
          ),
        ),
      );
      children.add(const SizedBox(height: 8));

      for (var i = 0; i < group.members.length; i++) {
        final contestant = group.members[i];
        children.add(_buildContestantButton(theme, contestant));
        if (i < group.members.length - 1) {
          children.add(const SizedBox(height: 12));
        }
      }

      if (groupIndex < groups.length - 1) {
        children.add(const SizedBox(height: 20));
      }
    }

    return Scrollbar(child: ListView(children: children));
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

  Color? _parseColorHex(String? source) {
    if (source == null) {
      return null;
    }
    final value = source.trim();
    if (value.isEmpty) {
      return null;
    }
    final normalized = value.toLowerCase();
    if (value.startsWith('#')) {
      final hex = value.substring(1);
      if (hex.length == 6) {
        final parsed = int.tryParse('FF$hex', radix: 16);
        if (parsed != null) {
          return Color(parsed);
        }
      } else if (hex.length == 8) {
        final parsed = int.tryParse(hex, radix: 16);
        if (parsed != null) {
          return Color(parsed);
        }
      }
    } else if (value.startsWith('0x')) {
      final parsed = int.tryParse(value.substring(2), radix: 16);
      if (parsed != null) {
        return Color(parsed);
      }
    } else {
      final named = _namedTribeColors[normalized];
      if (named != null) {
        return named;
      }
    }
    return null;
  }

  Color? _blendWithSurface(
    ThemeData theme,
    Color? color, {
    double strength = 0.2,
  }) {
    if (color == null) {
      return null;
    }
    final surface = theme.colorScheme.surface;
    final t = strength.clamp(0.0, 1.0);
    return Color.lerp(surface, color, t) ?? color;
  }

  FilledButton _buildContestantButton(
    ThemeData theme,
    AvailableContestant contestant,
  ) {
    final baseColor = _parseColorHex(contestant.tribeColor);
    final backgroundColor = _blendWithSurface(theme, baseColor, strength: 0.22);
    return FilledButton.tonal(
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        overlayColor: baseColor?.withValues(alpha: 0.12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: baseColor == null
              ? BorderSide.none
              : BorderSide(color: baseColor.withValues(alpha: 0.35)),
        ),
      ),
      onPressed: onContestantSelected == null
          ? null
          : () => onContestantSelected!(contestant),
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
  }

  List<_TribeGroup> _groupContestantsByTribe(
    List<AvailableContestant> contestants,
  ) {
    final groupsByKey = <String, _TribeGroup>{};
    final orderedGroups = <_TribeGroup>[];

    for (final contestant in contestants) {
      final rawName = contestant.tribeName?.trim() ?? '';
      final key = rawName.isEmpty ? '__none__' : rawName.toLowerCase();
      final displayName = rawName.isEmpty ? 'Unassigned' : rawName;

      var group = groupsByKey[key];
      if (group == null) {
        group = _TribeGroup(
          label: displayName,
          colorHex: contestant.tribeColor,
        );
        groupsByKey[key] = group;
        orderedGroups.add(group);
      } else if (group.colorHex == null && contestant.tribeColor != null) {
        group.colorHex = contestant.tribeColor;
      }

      group.members.add(contestant);
    }

    for (final group in orderedGroups) {
      group.members.sort((a, b) => a.name.compareTo(b.name));
    }

    return orderedGroups;
  }

  static const Map<String, Color> _namedTribeColors = {
    'purple': Color(0xFF8B5CF6),
    'violet': Color(0xFFA855F7),
    'blue': Color(0xFF3B82F6),
    'navy': Color(0xFF1D4ED8),
    'green': Color(0xFF22C55E),
    'teal': Color(0xFF14B8A6),
    'turquoise': Color(0xFF0EA5E9),
    'orange': Color(0xFFF97316),
    'yellow': Color(0xFFEAB308),
    'gold': Color(0xFFF59E0B),
    'red': Color(0xFFEF4444),
    'maroon': Color(0xFFB91C1C),
    'pink': Color(0xFFEC4899),
    'magenta': Color(0xFFD946EF),
    'brown': Color(0xFF92400E),
  };
}

class _TribeGroup {
  _TribeGroup({required this.label, this.colorHex});

  final String label;
  String? colorHex;
  final List<AvailableContestant> members = [];
}
