import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:survivor_pool/core/constants/api.dart';
import 'package:survivor_pool/core/constants/layout.dart';
import 'package:survivor_pool/core/models/pool.dart';
import 'package:survivor_pool/core/models/pool_leaderboard.dart';
import 'package:survivor_pool/core/layout/adaptive_page.dart';
import 'package:survivor_pool/core/network/auth_client.dart';

class PoolLeaderboardPage extends StatefulWidget {
  final PoolOption pool;
  final String userId;

  const PoolLeaderboardPage({
    super.key,
    required this.pool,
    required this.userId,
  });

  @override
  State<PoolLeaderboardPage> createState() => _PoolLeaderboardPageState();
}

class _PoolLeaderboardPageState extends State<PoolLeaderboardPage> {
  PoolLeaderboard? _leaderboard;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_loadLeaderboard());
  }

  Future<void> _loadLeaderboard() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    PoolLeaderboard? parsed;
    String? error;

    try {
      final response = await AuthHttpClient.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/pools/${widget.pool.id}/leaderboard?user_id=${widget.userId}',
        ),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          parsed = PoolLeaderboard.fromJson(decoded);
        } else {
          error = 'Failed to parse leaderboard data.';
        }
      } else {
        error = _parseError(response.body, 'Unable to load leaderboard.');
      }
    } catch (err) {
      error = 'Network error: $err';
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _leaderboard = error == null ? parsed : null;
      _error = error;
      _isLoading = false;
    });
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
      // Ignore JSON parsing issues to keep UI quiet.
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Leaderboard — ${widget.pool.name}'),
        automaticallyImplyLeading: !kIsWeb,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final body = _buildBody(theme, constraints);
          return PlatformRefresh(
            onRefresh: kIsWeb ? null : _loadLeaderboard,
            child: body,
          );
        },
      ),
    );
  }

  Widget _buildBody(ThemeData theme, BoxConstraints constraints) {
    final isWide = constraints.maxWidth >= AppBreakpoints.medium;
    final pagePadding = isWide
        ? const EdgeInsets.symmetric(horizontal: 64, vertical: 32)
        : const EdgeInsets.symmetric(horizontal: 24, vertical: 24);

    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 260,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          AdaptivePage(
            maxWidth: 900,
            compactPadding: pagePadding,
            widePadding: pagePadding,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Something went wrong',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.tonalIcon(
                      onPressed: _loadLeaderboard,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final leaderboard = _leaderboard;
    if (leaderboard == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 260,
            child: Center(child: Text('Leaderboard unavailable.')),
          ),
        ],
      );
    }

    if (leaderboard.entries.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          AdaptivePage(
            maxWidth: 900,
            compactPadding: pagePadding,
            widePadding: pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(theme, leaderboard),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No leaderboard standings yet. Check back once members start playing.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final entryCards = <Widget>[
      _buildHeaderCard(theme, leaderboard),
      const SizedBox(height: 24),
      ...List.generate(leaderboard.entries.length, (index) {
        final entry = leaderboard.entries[index];
        final card = _buildEntryCard(theme, entry);
        if (index == leaderboard.entries.length - 1) {
          return card;
        }
        return Column(children: [card, const SizedBox(height: 16)]);
      }),
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        AdaptivePage(
          maxWidth: 1000,
          compactPadding: pagePadding,
          widePadding: pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entryCards,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCard(ThemeData theme, PoolLeaderboard leaderboard) {
    final lines = <Widget>[
      Text(
        'Week ${leaderboard.currentWeek}',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        leaderboard.isCompleted ? 'Pool completed' : 'Pool in progress',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ];

    if (leaderboard.poolCompletedWeek != null) {
      lines.add(const SizedBox(height: 6));
      lines.add(
        Text(
          'Completed in week ${leaderboard.poolCompletedWeek}.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    if (leaderboard.poolCompletedAt != null) {
      lines.add(const SizedBox(height: 6));
      lines.add(
        Text(
          'Completed on ${_formatTimestamp(leaderboard.poolCompletedAt!)}.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    if (leaderboard.isCompleted) {
      lines.add(const SizedBox(height: 16));
      if (leaderboard.winners.isNotEmpty) {
        final winnerLabel = leaderboard.didTie ? 'Winners' : 'Winner';
        lines.add(
          Text(
            '$winnerLabel:',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        );
        lines.add(const SizedBox(height: 8));
        for (var i = 0; i < leaderboard.winners.length; i++) {
          final winner = leaderboard.winners[i];
          lines.add(
            Text(winner.displayName, style: theme.textTheme.bodyMedium),
          );
          if (i < leaderboard.winners.length - 1) {
            lines.add(const SizedBox(height: 6));
          }
        }
      } else {
        lines.add(
          Text(
            'Final standings locked. Winners coming soon.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }
    }

    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 96),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: lines,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEntryCard(ThemeData theme, PoolLeaderboardEntry entry) {
    final isEliminated = entry.status == 'eliminated';
    final accentColor = entry.isWinner
        ? theme.colorScheme.primary
        : isEliminated
        ? theme.colorScheme.error
        : theme.colorScheme.secondary;

    final rankBackground = accentColor.withValues(alpha: 0.12);
    final chips = _describeEntryLines(theme, entry, accentColor);
    final scoreLabel = entry.score == 1 ? 'choice' : 'choices';

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: rankBackground,
          child: Text(
            '${entry.rank}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
        ),
        title: Text(
          entry.displayName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: entry.isWinner ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        subtitle: chips,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${entry.score}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              scoreLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _describeEntryLines(
    ThemeData theme,
    PoolLeaderboardEntry entry,
    Color accent,
  ) {
    final lines = <String>[];

    if (entry.isWinner) {
      lines.add('Winner');
      if (entry.finalRank != null) {
        lines.add('Final rank ${entry.finalRank}');
      }
    } else if (entry.status == 'eliminated') {
      final week = entry.eliminatedWeek;
      final base = week != null ? 'Eliminated in week $week' : 'Eliminated';
      final reason = _describeEliminationReason(entry.eliminationReason);
      lines.add(reason != null ? '$base · $reason' : base);
      if (entry.finishedWeek != null) {
        lines.add('Finished week ${entry.finishedWeek}');
      }
      if (entry.finishedDate != null) {
        lines.add('Finished on ${_formatTimestamp(entry.finishedDate!)}');
      }
    } else {
      lines.add('Active');
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: lines
            .map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  line,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: line.startsWith('Winner')
                        ? accent
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  String? _describeEliminationReason(String? reason) {
    switch (reason) {
      case 'missed_pick':
        return 'Missed pick';
      case 'contestant_voted_out':
        return 'Pick voted out';
      case 'no_options_left':
        return 'No options left';
      default:
        return null;
    }
  }

  String _formatTimestamp(DateTime value) {
    final local = value.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$month/$day/$year $hour:$minute';
  }
}
