import 'package:flutter/material.dart';

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

    if (detail.age != null) {
      chips.add(_buildInfoChip('Age', detail.age.toString(), theme));
    }
    if (detail.occupation != null && detail.occupation!.isNotEmpty) {
      chips.add(_buildInfoChip('Occupation', detail.occupation!, theme));
    }
    if (detail.hometown != null && detail.hometown!.isNotEmpty) {
      chips.add(_buildInfoChip('Hometown', detail.hometown!, theme));
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
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
                    const SizedBox(height: 12),
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
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.detail.isAvailable && !_isSubmitting
                      ? _handleLock
                      : null,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_outline),
                  label: Text(
                    widget.detail.isAvailable ? 'Lock Pick' : 'Unavailable',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
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
