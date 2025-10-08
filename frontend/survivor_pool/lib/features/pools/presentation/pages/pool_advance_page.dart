import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:survivor_pool/core/constants/api.dart';
import 'package:survivor_pool/core/constants/layout.dart';
import 'package:survivor_pool/core/layout/adaptive_page.dart';
import 'package:survivor_pool/core/models/pool.dart';
import 'package:survivor_pool/core/models/pool_advance.dart';
import 'package:survivor_pool/core/widgets/confirmation_dialog.dart';

class PoolAdvancePage extends StatefulWidget {
  final PoolOption pool;
  final String userId;

  const PoolAdvancePage({super.key, required this.pool, required this.userId});

  @override
  State<PoolAdvancePage> createState() => _PoolAdvancePageState();
}

class _PoolAdvancePageState extends State<PoolAdvancePage> {
  PoolAdvanceStatus? _status;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_loadStatus());
  }

  Future<void> _loadStatus() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/pools/${widget.pool.id}/advance-status?user_id=${widget.userId}',
        ),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          final status = PoolAdvanceStatus.fromJson(decoded);
          if (mounted) {
            setState(() {
              _status = status;
              _error = null;
            });
          }
        } else {
          _setError('Failed to parse status.');
        }
      } else {
        _setError(_parseError(response.body, 'Unable to load status.'));
      }
    } catch (error) {
      _setError('Network error: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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
      // Ignored to keep UI quiet without snackbars.
    }
    return fallback;
  }

  void _setError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _error = message;
      _status = null;
    });
  }

  Future<void> _confirmAdvance() async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Confirm action',
      message: 'Are you sure you would like to advance to the next week?',
    );

    if (!mounted || !confirmed) {
      return;
    }

    if (!_isSubmitting) {
      unawaited(Future<void>.delayed(Duration.zero, _submitAdvance));
    }
  }

  Future<void> _submitAdvance() async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/pools/${widget.pool.id}/advance-week'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': widget.userId}),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          final rawWeek = decoded['new_current_week'];
          final newWeek = _asInt(rawWeek);
          final eliminationData = decoded['eliminations'];
          final eliminations = eliminationData is List
              ? eliminationData
                    .whereType<Map<String, dynamic>>()
                    .map(PoolAdvanceElimination.fromJson)
                    .where((entry) => entry.userId.isNotEmpty)
                    .toList()
              : <PoolAdvanceElimination>[];
          final poolCompleted = decoded['pool_completed'] == true;
          final winnersData = decoded['winners'];
          final winners = winnersData is List
              ? winnersData
                    .whereType<Map<String, dynamic>>()
                    .map(PoolWinner.fromJson)
                    .where((winner) => winner.userId.isNotEmpty)
                    .toList()
              : <PoolWinner>[];
          if (newWeek > 0 && mounted) {
            Navigator.of(context).pop({
              'newWeek': newWeek,
              'eliminations': eliminations,
              'poolCompleted': poolCompleted,
              'winners': winners,
            });
            return;
          }
        }
      }
    } catch (_) {
      // Ignored to keep UI quiet without snackbars.
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  Widget _buildBody(ThemeData theme, {required bool isWide}) {
    final padding = isWide
        ? const EdgeInsets.symmetric(horizontal: 64, vertical: 32)
        : const EdgeInsets.all(24);

    Widget wrapContent(List<Widget> content) {
      if (isWide) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Padding(
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: content,
                ),
              ),
            ),
          ),
        );
      }

      return ListView(
        padding: padding,
        physics: const AlwaysScrollableScrollPhysics(),
        children: content,
      );
    }

    if (_isLoading) {
      return wrapContent(const [
        SizedBox(
          height: 320,
          child: Center(child: CircularProgressIndicator()),
        ),
      ]);
    }

    if (_error != null) {
      return wrapContent([
        Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unable to load status',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(_error!, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _isSubmitting ? null : _loadStatus,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ]);
    }

    final status = _status;
    if (status == null) {
      return wrapContent(const [SizedBox(height: 1)]);
    }

    final missing = status.missingMembers;
    final content = <Widget>[
      Text(
        widget.pool.name,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Current week ${status.currentWeek}',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 24),
      Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMetricRow(
                theme,
                'Active members',
                status.activeMemberCount,
              ),
              const SizedBox(height: 12),
              _buildMetricRow(theme, 'Picks locked', status.lockedCount),
              const SizedBox(height: 12),
              _buildMetricRow(theme, 'Missing picks', status.missingCount),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
      if (!status.canAdvance)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Next week data is not available yet. Pull to refresh after the season data is updated.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      if (!status.canAdvance) const SizedBox(height: 24),
      Text(
        'Members without picks',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 12),
      if (missing.isEmpty)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'All active members have locked their picks.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        )
      else
        ...missing.map(
          (member) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(
                member.displayName,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              subtitle: isWide
                  ? Text(
                      'Awaiting pick',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      const SizedBox(height: 80),
    ];

    return wrapContent(content);
  }

  Widget _buildMetricRow(ThemeData theme, String label, int value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          value.toString(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _status;
    final canSubmit =
        !_isSubmitting && !_isLoading && status != null && status.canAdvance;

    return Scaffold(
      appBar: AppBar(title: const Text('Advance Week')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= AppBreakpoints.medium;
            final body = _buildBody(theme, isWide: isWide);
            return PlatformRefresh(
              onRefresh: kIsWeb ? null : _loadStatus,
              child: body,
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: canSubmit ? _confirmAdvance : null,
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Advance'),
          ),
        ),
      ),
    );
  }
}
