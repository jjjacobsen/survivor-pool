import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:survivor_pool/core/constants/layout.dart';
import 'package:survivor_pool/core/layout/adaptive_page.dart';
import 'package:survivor_pool/core/models/contestant.dart';
import 'package:survivor_pool/core/models/pool.dart';
import 'package:survivor_pool/core/widgets/confirmation_dialog.dart';

class ContestantDetailPage extends StatefulWidget {
  final PoolOption pool;
  final ContestantDetailResponse detail;
  final Future<bool> Function() onLockPick;

  const ContestantDetailPage({
    super.key,
    required this.pool,
    required this.detail,
    required this.onLockPick,
  });

  @override
  State<ContestantDetailPage> createState() => _ContestantDetailPageState();
}

class _ContestantDetailPageState extends State<ContestantDetailPage> {
  bool _isSubmitting = false;

  Future<void> _handleLock() async {
    if (_isSubmitting || !widget.detail.isAvailable) {
      return;
    }

    final contestant = widget.detail.contestant;
    final name = contestant.name.isEmpty ? 'this pick' : contestant.name;
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Lock pick',
      message:
          'Lock $name for week ${widget.pool.currentWeek}? This cannot be undone.',
      confirmLabel: 'Lock pick',
    );

    if (!mounted || !confirmed) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final success = await widget.onLockPick();
    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = widget.detail.contestant;
    final chips = <Widget>[];

    if (detail.tribeName != null && detail.tribeName!.isNotEmpty) {
      chips.add(
        _buildInfoChip(
          'Tribe',
          detail.tribeName!,
          theme,
          colorHex: detail.tribeColor,
        ),
      );
    }
    if (detail.age != null) {
      chips.add(_buildInfoChip('Age', detail.age.toString(), theme));
    }
    if (detail.occupation != null && detail.occupation!.isNotEmpty) {
      chips.add(_buildInfoChip('Occupation', detail.occupation!, theme));
    }
    if (detail.hometown != null && detail.hometown!.isNotEmpty) {
      chips.add(_buildInfoChip('Hometown', detail.hometown!, theme));
    }
    if (detail.advantages.isNotEmpty) {
      for (final advantage in detail.advantages) {
        chips.add(
          _buildAdvantageChip(advantage, theme, widget.pool.currentWeek),
        );
      }
    }

    final statusNotes = <Widget>[];
    if (widget.detail.currentPick != null &&
        widget.detail.currentPick!.contestantId != detail.id) {
      final pick = widget.detail.currentPick!;
      statusNotes.add(
        _buildStatusNote(
          theme,
          'You already locked ${pick.contestantName} for week ${pick.week}.',
        ),
      );
    }

    final alreadyPickedWeek = widget.detail.alreadyPickedWeek;
    final currentPickId = widget.detail.currentPick?.contestantId;
    if (alreadyPickedWeek != null && currentPickId != detail.id) {
      statusNotes.add(
        _buildStatusNote(
          theme,
          'You previously picked ${detail.name} in week $alreadyPickedWeek.',
        ),
      );
    }

    if (widget.detail.eliminatedWeek != null) {
      statusNotes.add(
        _buildStatusNote(
          theme,
          '${detail.name} was eliminated in week ${widget.detail.eliminatedWeek}.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(detail.name.isEmpty ? 'Contestant' : detail.name),
        automaticallyImplyLeading: !kIsWeb,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= AppBreakpoints.medium;
            final footerDecoration = BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.5),
                ),
              ),
              boxShadow: isWide
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ]
                  : null,
            );

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: AdaptivePage(
                      maxWidth: 900,
                      compactPadding: const EdgeInsets.all(24),
                      widePadding: const EdgeInsets.symmetric(
                        horizontal: 64,
                        vertical: 32,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detail.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Week ${widget.pool.currentWeek} · ${widget.pool.name}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (chips.isNotEmpty)
                            Wrap(spacing: 12, runSpacing: 12, children: chips),
                          if (statusNotes.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            ...statusNotes,
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  decoration: footerDecoration,
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 64 : 24,
                    vertical: isWide ? 24 : 20,
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: ElevatedButton.icon(
                        onPressed: widget.detail.isAvailable && !_isSubmitting
                            ? _handleLock
                            : null,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.lock_outline),
                        label: Text(
                          widget.detail.isAvailable
                              ? 'Lock Pick'
                              : 'Unavailable',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    String label,
    String value,
    ThemeData theme, {
    String? colorHex,
    Color? color,
  }) {
    final accent =
        color ?? _tryParseColor(colorHex) ?? theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withAlpha(32),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildAdvantageChip(
    ContestantAdvantage advantage,
    ThemeData theme,
    int currentWeek,
  ) {
    final endWeek = advantage.endWeek;
    final hasAdvantage = endWeek == null || endWeek > currentWeek;
    final acquisition = advantage.acquisitionNotes?.trim() ?? '';
    final endNotes = advantage.endNotes?.trim() ?? '';
    final activeText = acquisition.isNotEmpty
        ? acquisition
        : (advantage.value.isNotEmpty ? advantage.value : advantage.label);
    final usedText = endNotes.isNotEmpty
        ? endNotes
        : (advantage.value.isNotEmpty ? advantage.value : advantage.label);
    return _buildInfoChip(
      advantage.label,
      hasAdvantage ? activeText : usedText,
      theme,
      colorHex: hasAdvantage ? '#F5B74E' : null,
      color: hasAdvantage ? null : theme.colorScheme.error,
    );
  }

  Color? _tryParseColor(String? source) {
    if (source == null) {
      return null;
    }
    final value = source.trim();
    if (value.isEmpty) {
      return null;
    }
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
    }
    return null;
  }

  Widget _buildStatusNote(ThemeData theme, String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withAlpha(46),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
