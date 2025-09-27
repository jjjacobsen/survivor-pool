import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:survivor_pool/app/routes.dart';
import 'package:survivor_pool/core/constants/api.dart';
import 'package:survivor_pool/core/models/contestant.dart';
import 'package:survivor_pool/core/models/pick.dart';
import 'package:survivor_pool/core/models/pool.dart';
import 'package:survivor_pool/core/models/season.dart';
import 'package:survivor_pool/core/models/user.dart';
import 'package:survivor_pool/features/picks/presentation/pages/contestant_detail_page.dart';
import 'package:survivor_pool/features/pools/presentation/pages/pool_advance_page.dart';
import 'package:survivor_pool/features/pools/presentation/pages/manage_pool_members_page.dart';
import 'package:survivor_pool/features/pools/presentation/widgets/create_pool_dialog.dart';
import 'package:survivor_pool/features/pools/presentation/widgets/pool_dashboard.dart';

class HomePage extends StatefulWidget {
  final AppUser user;

  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<SeasonOption> _seasons = [];
  bool _isLoadingSeasons = false;
  List<PoolOption> _pools = [];
  bool _isLoadingPools = false;
  int _poolsRequestToken = 0;
  String? _defaultPoolId;
  bool _isUpdatingDefault = false;
  List<AvailableContestant> _availableContestants = const [];
  bool _isLoadingContestants = false;
  String? _contestantsForPoolId;
  CurrentPickSummary? _currentPick;
  List<PendingInvite> _pendingInvites = const [];
  bool _isLoadingInvites = false;
  final Set<String> _inviteRequests = <String>{};

  Uri _apiUri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  List<PoolOption> _applySeasonNumbers(
    List<PoolOption> pools, {
    List<SeasonOption>? seasons,
  }) {
    final catalog = seasons ?? _seasons;
    if (catalog.isEmpty) {
      return pools;
    }

    final byId = {for (final season in catalog) season.id: season};

    return pools.map((pool) {
      final match = byId[pool.seasonId];
      if (match == null) {
        return pool;
      }
      final number = match.number;
      if (number == null || number == pool.seasonNumber) {
        return pool;
      }
      return pool.copyWith(seasonNumber: number);
    }).toList();
  }

  Future<void> _loadAvailableContestants(String? poolId) async {
    if (!mounted) {
      return;
    }

    if (poolId == null || poolId.isEmpty) {
      setState(() {
        _availableContestants = const [];
        _contestantsForPoolId = null;
        _isLoadingContestants = false;
        _currentPick = null;
      });
      return;
    }

    setState(() {
      _isLoadingContestants = true;
      if (_contestantsForPoolId != poolId) {
        _availableContestants = const [];
        _currentPick = null;
      }
      _contestantsForPoolId = poolId;
    });

    List<AvailableContestant> parsed = const <AvailableContestant>[];
    CurrentPickSummary? parsedCurrentPick;
    var updated = false;

    int? parsedWeek;

    try {
      final response = await http.get(
        _apiUri(
          '/pools/$poolId/available_contestants?user_id=${widget.user.id}',
        ),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          final rawWeek = decoded['current_week'];
          if (rawWeek is int) {
            parsedWeek = rawWeek;
          } else if (rawWeek is num) {
            parsedWeek = rawWeek.toInt();
          }
          final items = decoded['contestants'];
          if (items is List) {
            parsed = items
                .whereType<Map<String, dynamic>>()
                .map(AvailableContestant.fromJson)
                .where((contestant) => contestant.id.isNotEmpty)
                .toList();
            updated = true;
          }
          final pickData = decoded['current_pick'];
          if (pickData is Map<String, dynamic>) {
            parsedCurrentPick = CurrentPickSummary.fromJson(pickData);
          }
        }
      }
    } catch (_) {
      updated = false;
    } finally {
      if (mounted && _contestantsForPoolId == poolId) {
        setState(() {
          _isLoadingContestants = false;
          if (updated) {
            _availableContestants = parsed;
          }
          _currentPick = parsedCurrentPick;
          if (parsedWeek != null) {
            _pools = _pools
                .map(
                  (candidate) => candidate.id == poolId
                      ? candidate.copyWith(currentWeek: parsedWeek)
                      : candidate,
                )
                .toList();
          }
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _defaultPoolId = widget.user.defaultPoolId;
    _fetchSeasons();
    _loadPools();
    _loadInvites();
  }

  String _parseErrorMessage(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String && detail.isNotEmpty) {
          return detail;
        }
      }
    } catch (_) {
      // Ignore JSON parsing issues and fall through to default message.
    }
    return 'Failed to create pool. Please try again.';
  }

  Future<bool> _fetchSeasons() async {
    if (_isLoadingSeasons) {
      return _seasons.isNotEmpty;
    }

    if (mounted) {
      setState(() {
        _isLoadingSeasons = true;
      });
    }

    var success = _seasons.isNotEmpty;
    List<SeasonOption>? fetched;

    try {
      final response = await http.get(_apiUri('/seasons'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          final list = data
              .whereType<Map<String, dynamic>>()
              .map(SeasonOption.fromJson)
              .where((season) => season.id.isNotEmpty)
              .toList();

          list.sort((a, b) => (b.number ?? 0).compareTo(a.number ?? 0));

          fetched = list;
          success = list.isNotEmpty;
        }
      }
    } catch (_) {
      success = _seasons.isNotEmpty;
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSeasons = false;
          final seasons = fetched;
          if (seasons != null) {
            _seasons = seasons;
            _pools = _applySeasonNumbers(_pools, seasons: seasons);
          }
        });
      }
    }

    return success;
  }

  Future<void> _loadPools({
    bool force = false,
    bool loadDefaultContestants = true,
  }) async {
    if (_isLoadingPools && !force) {
      return;
    }

    final requestId = ++_poolsRequestToken;

    setState(() {
      _isLoadingPools = true;
    });

    try {
      final response = await http.get(
        _apiUri('/users/${widget.user.id}/pools'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          final mapped = data
              .whereType<Map<String, dynamic>>()
              .map(PoolOption.fromJson)
              .where((pool) => pool.id.isNotEmpty)
              .toList();
          mapped.sort((a, b) => a.name.compareTo(b.name));
          final decorated = _applySeasonNumbers(mapped);

          if (mounted && requestId == _poolsRequestToken) {
            final existingById = {for (final pool in _pools) pool.id: pool};
            final merged = decorated.map((pool) {
              final existing = existingById[pool.id];
              if (existing == null) {
                return pool;
              }
              return existing.copyWith(
                name: pool.name,
                seasonId: pool.seasonId,
                ownerId: pool.ownerId,
                seasonNumber: pool.seasonNumber,
              );
            }).toList();
            setState(() {
              _pools = merged;
              if (_defaultPoolId != null &&
                  !merged.any((pool) => pool.id == _defaultPoolId)) {
                _defaultPoolId = null;
              }
            });
            if (loadDefaultContestants) {
              unawaited(_loadAvailableContestants(_defaultPoolId));
            }
          }
        }
      }
    } catch (_) {
      // Ignore errors; the selector UI will remain unchanged.
    } finally {
      if (mounted && requestId == _poolsRequestToken) {
        setState(() {
          _isLoadingPools = false;
        });
      }
    }
  }

  Future<void> _loadInvites() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoadingInvites = true;
    });

    try {
      final response = await http.get(
        _apiUri('/users/${widget.user.id}/invites'),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          final list = decoded['invites'];
          final invites = list is List
              ? list
                    .whereType<Map<String, dynamic>>()
                    .map(PendingInvite.fromJson)
                    .where((invite) => invite.poolId.isNotEmpty)
                    .toList()
              : <PendingInvite>[];
          if (mounted) {
            setState(() {
              _pendingInvites = invites;
            });
          }
        }
      }
    } catch (_) {
      // Leave existing invites untouched on failure.
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInvites = false;
        });
      }
    }
  }

  Future<void> _refreshHome() async {
    await _loadInvites();
    final selected = _defaultPoolId;
    if (selected != null) {
      await _loadAvailableContestants(selected);
    }
  }

  Future<void> _handleInviteAction(PendingInvite invite, String action) async {
    if (_inviteRequests.contains(invite.poolId)) {
      return;
    }

    setState(() {
      _inviteRequests.add(invite.poolId);
    });

    try {
      final response = await http.post(
        _apiUri('/pools/${invite.poolId}/invites/respond'),
        headers: const {'Content-Type': 'application/json'},
        body: json.encode({'user_id': widget.user.id, 'action': action}),
      );

      if (response.statusCode == 200) {
        await _loadInvites();
        if (action == 'accept') {
          await _loadPools(loadDefaultContestants: false);
          await _updateDefaultPool(invite.poolId);
        }
      }
    } catch (_) {
      // Ignore failures so user can retry.
    } finally {
      if (mounted) {
        setState(() {
          _inviteRequests.remove(invite.poolId);
        });
      }
    }
  }

  Future<void> _handleManageMembers(PoolOption pool) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ManagePoolMembersPage(pool: pool, ownerId: widget.user.id),
      ),
    );
  }

  Future<bool> _ensureSeasonsLoaded() async {
    if (_seasons.isNotEmpty) {
      return true;
    }

    final loaded = await _fetchSeasons();
    return loaded;
  }

  Future<ContestantDetailResponse?> _fetchContestantDetail(
    String poolId,
    String contestantId,
  ) async {
    try {
      final response = await http.get(
        _apiUri(
          '/pools/$poolId/contestants/$contestantId?user_id=${widget.user.id}',
        ),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return ContestantDetailResponse.fromJson(decoded);
        }
      }
    } catch (_) {
      // Ignored to keep UI quiet without snackbars.
    }
    return null;
  }

  Future<PickResponse?> _lockPick(String poolId, String contestantId) async {
    try {
      final response = await http.post(
        _apiUri('/pools/$poolId/picks'),
        headers: const {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.user.id,
          'contestant_id': contestantId,
        }),
      );

      if (response.statusCode == 201) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return PickResponse.fromJson(decoded);
        }
      }
    } catch (_) {
      // Ignored to keep UI quiet without snackbars.
    }
    return null;
  }

  Future<void> _handleContestantSelected(
    PoolOption pool,
    AvailableContestant contestant,
  ) async {
    final detail = await _fetchContestantDetail(pool.id, contestant.id);
    if (!mounted || detail == null) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContestantDetailPage(
          pool: pool,
          detail: detail,
          onLockPick: () => _handleLockPick(pool, detail.contestant),
        ),
      ),
    );
  }

  Future<void> _handleAdvanceWeek(PoolOption pool) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) =>
            PoolAdvancePage(pool: pool, userId: widget.user.id),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    final rawWeek = result['newWeek'];
    if (rawWeek is! int) {
      return;
    }

    final newWeek = rawWeek <= 0 ? 1 : rawWeek;

    setState(() {
      _pools = _pools
          .map(
            (candidate) => candidate.id == pool.id
                ? candidate.copyWith(currentWeek: newWeek)
                : candidate,
          )
          .toList();
      if (_defaultPoolId == pool.id) {
        _currentPick = null;
        _availableContestants = const [];
        _contestantsForPoolId = null;
        _isLoadingContestants = true;
      }
    });

    unawaited(_loadAvailableContestants(pool.id));
  }

  Future<bool> _handleLockPick(
    PoolOption pool,
    ContestantDetail contestant,
  ) async {
    final pick = await _lockPick(pool.id, contestant.id);
    if (pick == null) {
      return false;
    }

    if (!mounted) {
      return true;
    }

    final summary = CurrentPickSummary(
      id: pick.id,
      contestantId: pick.contestantId,
      contestantName: contestant.name.isNotEmpty
          ? contestant.name
          : pick.contestantId,
      week: pick.week,
      lockedAt: pick.lockedAt,
    );

    setState(() {
      _currentPick = summary;
    });

    await _loadAvailableContestants(pool.id);
    return true;
  }

  Future<void> _showCreatePoolDialog() async {
    final ready = await _ensureSeasonsLoaded();
    if (!mounted || !ready) {
      return;
    }

    final created = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CreatePoolDialog(
        seasons: List<SeasonOption>.from(_seasons),
        ownerId: widget.user.id,
        parseErrorMessage: _parseErrorMessage,
      ),
    );

    if (created != null) {
      final newPool = PoolOption.fromJson(created);
      if (newPool.id.isNotEmpty) {
        setState(() {
          _pools = [..._pools.where((pool) => pool.id != newPool.id), newPool]
            ..sort((a, b) => a.name.compareTo(b.name));
          _defaultPoolId = newPool.id;
          _availableContestants = const [];
          _contestantsForPoolId = null;
          _isLoadingContestants = true;
        });
      }

      unawaited(_loadPools());
    }
  }

  Future<void> _updateDefaultPool(String? poolId) async {
    if (_isUpdatingDefault || _defaultPoolId == poolId) {
      return;
    }

    final previous = _defaultPoolId;

    setState(() {
      _isUpdatingDefault = true;
      _defaultPoolId = poolId;
    });
    unawaited(_loadAvailableContestants(poolId));
    unawaited(_loadInvites());

    try {
      final response = await http.patch(
        _apiUri('/users/${widget.user.id}/default_pool'),
        headers: const {'Content-Type': 'application/json'},
        body: json.encode({'default_pool': poolId}),
      );

      if (response.statusCode != 200) {
        if (mounted) {
          setState(() {
            _defaultPoolId = previous;
          });
        }
        unawaited(_loadAvailableContestants(previous));
      } else {
        final decoded = json.decode(response.body);
        final serverDefault = decoded is Map<String, dynamic>
            ? decoded['default_pool'] as String?
            : null;
        if (mounted) {
          setState(() {
            _defaultPoolId = serverDefault;
          });
        }
        if (serverDefault != poolId) {
          unawaited(_loadAvailableContestants(serverDefault));
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _defaultPoolId = previous;
        });
      }
      unawaited(_loadAvailableContestants(previous));
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingDefault = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safeDefaultPoolId =
        (_defaultPoolId != null &&
            _pools.any((pool) => pool.id == _defaultPoolId))
        ? _defaultPoolId
        : null;

    final selectedPool = safeDefaultPoolId == null
        ? null
        : _pools.firstWhere(
            (pool) => pool.id == safeDefaultPoolId,
            orElse: () => PoolOption(
              id: safeDefaultPoolId,
              name: 'Unknown Pool',
              seasonId: '',
              ownerId: null,
              seasonNumber: null,
              currentWeek: 1,
            ),
          );

    final isOwnerView =
        selectedPool != null &&
        (selectedPool.ownerId == null ||
            selectedPool.ownerId == widget.user.id);
    List<AvailableContestant> availableContestants;
    var isLoadingContestants = false;
    if (selectedPool == null) {
      availableContestants = const <AvailableContestant>[];
    } else if (_contestantsForPoolId == selectedPool.id) {
      availableContestants = _availableContestants;
      isLoadingContestants = _isLoadingContestants;
    } else {
      availableContestants = const <AvailableContestant>[];
      isLoadingContestants = true;
    }

    final currentPick = (_contestantsForPoolId == selectedPool?.id)
        ? _currentPick
        : null;
    final showInvites = _pendingInvites.isNotEmpty && safeDefaultPoolId == null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 12,
        title: _buildDefaultPoolSelector(theme, safeDefaultPoolId),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshHome,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              if (showInvites) _buildInvitesBanner(theme),
              if (showInvites) const SizedBox(height: 16),
              _buildMainSection(
                theme: theme,
                selectedPool: selectedPool,
                isOwnerView: isOwnerView,
                availableContestants: availableContestants,
                isLoadingContestants: isLoadingContestants,
                currentPick: currentPick,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainSection({
    required ThemeData theme,
    required PoolOption? selectedPool,
    required bool isOwnerView,
    required List<AvailableContestant> availableContestants,
    required bool isLoadingContestants,
    required CurrentPickSummary? currentPick,
  }) {
    if (_isLoadingPools && _pools.isEmpty) {
      return const SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_defaultPoolId != null && selectedPool != null) {
      return PoolDashboard(
        pool: selectedPool,
        availableContestants: availableContestants,
        isLoadingContestants: isLoadingContestants,
        currentPick: currentPick,
        onManageMembers: isOwnerView
            ? () => _handleManageMembers(selectedPool)
            : null,
        onManageSettings: isOwnerView ? () {} : null,
        onAdvanceWeek: isOwnerView
            ? () => _handleAdvanceWeek(selectedPool)
            : null,
        onContestantSelected: (contestant) {
          _handleContestantSelected(selectedPool, contestant);
        },
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group_add_outlined, size: 80, color: theme.primaryColor),
            const SizedBox(height: 24),
            Text(
              _pools.isEmpty ? 'No pools yet' : 'Select a pool',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _pools.isEmpty
                  ? 'Create a new pool or use an invite to get started.'
                  : 'Choose a default pool from the dropdown above to view its details.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isLoadingSeasons ? null : _showCreatePoolDialog,
                child: _isLoadingSeasons
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Pool Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitesBanner(ThemeData theme) {
    if (_pendingInvites.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mail_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Pool invites',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (_isLoadingInvites)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ..._pendingInvites.map((invite) => _buildInviteRow(theme, invite)),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteRow(ThemeData theme, PendingInvite invite) {
    final busy = _inviteRequests.contains(invite.poolId);
    final subtitle = _formatInviteSubtitle(invite);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            invite.poolName.isNotEmpty ? invite.poolName : 'Untitled pool',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton(
                onPressed: busy
                    ? null
                    : () => _handleInviteAction(invite, 'accept'),
                child: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Accept'),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: busy
                    ? null
                    : () => _handleInviteAction(invite, 'decline'),
                child: const Text('Decline'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatInviteSubtitle(PendingInvite invite) {
    final parts = <String>[];
    if (invite.seasonNumber != null) {
      parts.add('Season ${invite.seasonNumber}');
    }
    if (invite.ownerDisplayName.isNotEmpty) {
      parts.add('Hosted by ${invite.ownerDisplayName}');
    }
    return parts.join(' • ');
  }

  Widget _buildDefaultPoolSelector(ThemeData theme, String? selectedPoolId) {
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );

    final allPools = <({String? id, String label})>[
      (id: null, label: 'Home'),
      ..._pools.map((pool) => (id: pool.id, label: pool.name)),
    ];

    final items = allPools
        .map(
          (entry) => _buildPoolMenuItem(
            entry.id,
            entry.label,
            theme,
            isSelected: selectedPoolId == entry.id,
          ),
        )
        .toList();

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(61),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withAlpha(89), width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: selectedPoolId,
                      isExpanded: true,
                      items: items,
                      onChanged: _isUpdatingDefault
                          ? null
                          : (value) => _updateDefaultPool(value),
                      style: textStyle,
                      dropdownColor: theme.colorScheme.surface,
                      iconEnabledColor: Colors.white,
                      menuMaxHeight: 320,
                      borderRadius: BorderRadius.circular(12),
                      selectedItemBuilder: (context) => allPools
                          .map(
                            (entry) => Row(
                              children: [
                                Icon(
                                  entry.id == null
                                      ? Icons.home_outlined
                                      : Icons.flag_outlined,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    entry.label,
                                    overflow: TextOverflow.ellipsis,
                                    style: textStyle,
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                      hint: Text('Select pool', style: textStyle),
                    ),
                  ),
                ),
                if (_isUpdatingDefault || _isLoadingPools) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  DropdownMenuItem<String?> _buildPoolMenuItem(
    String? id,
    String label,
    ThemeData theme, {
    bool isSelected = false,
  }) {
    return DropdownMenuItem<String?>(
      value: id,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withAlpha(31)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(
              id == null ? Icons.home_outlined : Icons.flag_outlined,
              size: 18,
              color: isSelected ? theme.colorScheme.primary : Colors.grey[700],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
