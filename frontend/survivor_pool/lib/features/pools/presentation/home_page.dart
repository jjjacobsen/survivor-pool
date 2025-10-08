import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:survivor_pool/app/routes.dart';
import 'package:survivor_pool/core/constants/api.dart';
import 'package:survivor_pool/core/constants/layout.dart';
import 'package:survivor_pool/core/models/contestant.dart';
import 'package:survivor_pool/core/models/pick.dart';
import 'package:survivor_pool/core/models/pool.dart';
import 'package:survivor_pool/core/models/pool_advance.dart';
import 'package:survivor_pool/core/models/season.dart';
import 'package:survivor_pool/core/models/user.dart';
import 'package:survivor_pool/core/layout/adaptive_page.dart';
import 'package:survivor_pool/features/picks/presentation/pages/contestant_detail_page.dart';
import 'package:survivor_pool/features/pools/presentation/pages/pool_advance_page.dart';
import 'package:survivor_pool/features/pools/presentation/pages/manage_pool_members_page.dart';
import 'package:survivor_pool/features/pools/presentation/pages/pool_leaderboard_page.dart';
import 'package:survivor_pool/features/pools/presentation/pages/pool_settings_page.dart';
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
  int? _availableScore;
  bool _isEliminated = false;
  String? _eliminationReason;
  int? _eliminatedWeek;
  bool _isWinner = false;
  String _poolStatus = 'open';
  int? _poolCompletedWeek;
  DateTime? _poolCompletedAt;
  List<PoolWinner> _winners = const [];
  bool _didTie = false;
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
        _availableScore = null;
        _isEliminated = false;
        _eliminationReason = null;
        _eliminatedWeek = null;
        _isWinner = false;
        _poolStatus = 'open';
        _poolCompletedWeek = null;
        _poolCompletedAt = null;
        _winners = const [];
        _didTie = false;
      });
      return;
    }

    setState(() {
      _isLoadingContestants = true;
      if (_contestantsForPoolId != poolId) {
        _availableContestants = const [];
        _currentPick = null;
        _availableScore = null;
        _isEliminated = false;
        _eliminationReason = null;
        _eliminatedWeek = null;
        _isWinner = false;
        _poolStatus = 'open';
        _poolCompletedWeek = null;
        _poolCompletedAt = null;
        _winners = const [];
        _didTie = false;
      }
      _contestantsForPoolId = poolId;
    });

    List<AvailableContestant> parsedContestants = const <AvailableContestant>[];
    var parsedContestantsUpdated = false;
    CurrentPickSummary? parsedCurrentPick;
    var parsedEliminated = false;
    String? parsedEliminationReason;
    int? parsedEliminatedWeek;
    int? parsedWeek;
    int? parsedScore;
    var parsedIsWinner = false;
    String parsedPoolStatus = 'open';
    int? parsedCompletedWeek;
    DateTime? parsedCompletedAt;
    List<PoolWinner> parsedWinners = const [];
    var parsedDidTie = false;

    int? parseOptionalInt(dynamic value) {
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        return int.tryParse(value);
      }
      return null;
    }

    DateTime? parseOptionalDate(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

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
          parsedWeek = parseOptionalInt(rawWeek);
          parsedScore = parseOptionalInt(decoded['score']);
          parsedIsWinner = decoded['is_winner'] == true;
          final statusValue = decoded['pool_status'];
          if (statusValue is String && statusValue.isNotEmpty) {
            parsedPoolStatus = statusValue;
          }
          parsedDidTie = decoded['did_tie'] == true;
          parsedCompletedWeek = parseOptionalInt(
            decoded['pool_completed_week'],
          );
          parsedCompletedAt = parseOptionalDate(decoded['pool_completed_at']);
          final winnersData = decoded['winners'];
          if (winnersData is List) {
            parsedWinners = winnersData
                .whereType<Map<String, dynamic>>()
                .map(PoolWinner.fromJson)
                .where((winner) => winner.userId.isNotEmpty)
                .toList();
          }

          parsedEliminated = decoded['is_eliminated'] == true;
          final rawReason = decoded['elimination_reason'];
          if (rawReason is String && rawReason.isNotEmpty) {
            parsedEliminationReason = rawReason;
          }
          parsedEliminatedWeek = parseOptionalInt(decoded['eliminated_week']);

          if (!parsedEliminated) {
            final items = decoded['contestants'];
            if (items is List) {
              parsedContestants = items
                  .whereType<Map<String, dynamic>>()
                  .map(AvailableContestant.fromJson)
                  .where((contestant) => contestant.id.isNotEmpty)
                  .toList();
              parsedContestantsUpdated = true;
            }
            final pickData = decoded['current_pick'];
            if (pickData is Map<String, dynamic>) {
              parsedCurrentPick = CurrentPickSummary.fromJson(pickData);
            }
          }
        }
      } else if (response.statusCode == 404) {
        _handleMissingPool(poolId);
        return;
      }
    } catch (_) {
      parsedContestantsUpdated = false;
    } finally {
      if (mounted && _contestantsForPoolId == poolId) {
        setState(() {
          _isLoadingContestants = false;
          _isEliminated = parsedEliminated;
          _eliminationReason = parsedEliminationReason;
          _eliminatedWeek = parsedEliminatedWeek;
          _isWinner = parsedIsWinner;
          _poolStatus = parsedPoolStatus;
          _poolCompletedWeek = parsedCompletedWeek;
          _poolCompletedAt = parsedCompletedAt;
          _winners = parsedWinners;
          _didTie = parsedDidTie;
          if (parsedEliminated) {
            _availableContestants = const [];
            _currentPick = null;
            if (parsedScore != null) {
              _availableScore = parsedScore;
            } else {
              _availableScore = 0;
            }
          } else {
            if (parsedContestantsUpdated) {
              _availableContestants = parsedContestants;
            }
            _currentPick = parsedCurrentPick;
            if (parsedScore != null) {
              _availableScore = parsedScore;
            } else if (parsedContestantsUpdated) {
              _availableScore = parsedContestants.length;
            }
          }
          final updatedWinnerIds = parsedPoolStatus == 'completed'
              ? parsedWinners.map((winner) => winner.userId).toList()
              : <String>[];
          _pools = _pools.map((candidate) {
            if (candidate.id != poolId) {
              return candidate;
            }
            final newWeekValue = parsedWeek ?? candidate.currentWeek;
            final newCompletedWeek = parsedPoolStatus == 'completed'
                ? parsedCompletedWeek ?? candidate.completedWeek
                : candidate.completedWeek;
            final newCompletedAt = parsedPoolStatus == 'completed'
                ? parsedCompletedAt ?? candidate.completedAt
                : candidate.completedAt;
            return candidate.copyWith(
              currentWeek: newWeekValue,
              status: parsedPoolStatus,
              completedWeek: newCompletedWeek,
              completedAt: newCompletedAt,
              winnerUserIds: parsedPoolStatus == 'completed'
                  ? updatedWinnerIds
                  : <String>[],
            );
          }).toList();
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
            var nextDefault = _defaultPoolId;
            if (nextDefault != null &&
                !merged.any((pool) => pool.id == nextDefault)) {
              nextDefault = null;
            }
            setState(() {
              _pools = merged;
              _defaultPoolId = nextDefault;
            });
            if (loadDefaultContestants) {
              if (nextDefault == null && merged.isNotEmpty) {
                final firstPoolId = merged.first.id;
                if (firstPoolId.isNotEmpty && !_isUpdatingDefault) {
                  _updateDefaultPool(firstPoolId);
                }
              } else {
                unawaited(_loadAvailableContestants(nextDefault));
              }
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

  Future<void> _handleViewLeaderboard(PoolOption pool) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PoolLeaderboardPage(pool: pool, userId: widget.user.id),
      ),
    );
  }

  void _handleMissingPool(String poolId) {
    if (!mounted) {
      return;
    }

    setState(() {
      _pools = _pools
          .where((candidate) => candidate.id != poolId)
          .toList(growable: false);
      if (_contestantsForPoolId == poolId) {
        _contestantsForPoolId = null;
        _availableContestants = const [];
        _currentPick = null;
        _isLoadingContestants = false;
        _availableScore = null;
      }
      if (_defaultPoolId == poolId) {
        _defaultPoolId = null;
      }
    });

    unawaited(_loadPools(force: true));
  }

  Future<void> _handlePoolSettings(PoolOption pool) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => PoolSettingsPage(pool: pool, ownerId: widget.user.id),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    if (result['deleted'] == true) {
      setState(() {
        _pools = _pools
            .where((candidate) => candidate.id != pool.id)
            .toList(growable: false);
        if (_defaultPoolId == pool.id) {
          _defaultPoolId = null;
          _availableContestants = const [];
          _currentPick = null;
          _contestantsForPoolId = null;
          _availableScore = null;
        }
      });
      unawaited(_loadPools(force: true));
    }
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

    final eliminations = result['eliminations'];
    final eliminationSummaries = eliminations is List
        ? eliminations.whereType<PoolAdvanceElimination>().toList()
        : <PoolAdvanceElimination>[];

    final poolCompleted = result['poolCompleted'] == true;
    final winnersData = result['winners'];
    final winnerSummaries = winnersData is List
        ? winnersData.whereType<PoolWinner>().toList()
        : <PoolWinner>[];

    final newWeek = rawWeek <= 0 ? 1 : rawWeek;

    setState(() {
      final winnerIds = winnerSummaries.map((winner) => winner.userId).toList();
      _pools = _pools
          .map(
            (candidate) => candidate.id == pool.id
                ? candidate.copyWith(
                    currentWeek: newWeek,
                    status: poolCompleted ? 'completed' : candidate.status,
                    completedWeek: poolCompleted
                        ? candidate.completedWeek ?? newWeek
                        : candidate.completedWeek,
                    completedAt: poolCompleted
                        ? candidate.completedAt
                        : candidate.completedAt,
                    winnerUserIds: poolCompleted ? winnerIds : <String>[],
                  )
                : candidate,
          )
          .toList();
      if (_defaultPoolId == pool.id) {
        _currentPick = null;
        _availableContestants = const [];
        _contestantsForPoolId = null;
        _isLoadingContestants = true;
        if (poolCompleted) {
          _poolStatus = 'completed';
          _winners = winnerSummaries;
          _didTie = winnerSummaries.length > 1;
          _isWinner = winnerSummaries.any(
            (winner) => winner.userId == widget.user.id,
          );
        }
      }
    });

    unawaited(_loadAvailableContestants(pool.id));

    if (eliminationSummaries.isNotEmpty && mounted) {
      await _showEliminationSummary(eliminationSummaries);
    }
  }

  String _describeEliminationReason(String reason) {
    switch (reason) {
      case 'missed_pick':
        return 'Missed their pick';
      case 'contestant_voted_out':
        return 'Pick was voted out';
      case 'no_options_left':
        return 'No contestants left to choose';
      default:
        return 'Eliminated';
    }
  }

  Future<void> _showEliminationSummary(
    List<PoolAdvanceElimination> eliminations,
  ) async {
    if (!mounted) {
      return;
    }

    final theme = Theme.of(context);
    final message = eliminations
        .map(
          (entry) =>
              '${entry.displayName}: '
              '${_describeEliminationReason(entry.reason)}',
        )
        .join('\n');

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminations'),
          content: Text(message, style: theme.textTheme.bodyMedium),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
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

      if (response.statusCode == 404 && poolId != null) {
        _handleMissingPool(poolId);
        return;
      }

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
    final showInvites = _pendingInvites.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppBreakpoints.medium;
        final appBar = isWide
            ? _buildDesktopAppBar(theme: theme)
            : _buildMobileAppBar(theme, safeDefaultPoolId);

        final body = isWide
            ? _buildDesktopBody(
                theme: theme,
                selectedPool: selectedPool,
                isOwnerView: isOwnerView,
                availableContestants: availableContestants,
                isLoadingContestants: isLoadingContestants,
                currentPick: currentPick,
                score: _availableScore,
                showInvites: showInvites,
              )
            : _buildMobileBody(
                theme: theme,
                selectedPool: selectedPool,
                isOwnerView: isOwnerView,
                availableContestants: availableContestants,
                isLoadingContestants: isLoadingContestants,
                currentPick: currentPick,
                score: _availableScore,
                showInvites: showInvites,
              );

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: appBar,
          body: body,
        );
      },
    );
  }

  PreferredSizeWidget _buildMobileAppBar(
    ThemeData theme,
    String? selectedPoolId,
  ) {
    return AppBar(
      automaticallyImplyLeading: false,
      leadingWidth: 56,
      leading: _buildDefaultPoolSelector(theme, selectedPoolId),
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      actions: [_buildMobileProfileAction(theme)],
    );
  }

  PreferredSizeWidget _buildDesktopAppBar({required ThemeData theme}) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onSurface,
      toolbarHeight: 72,
      elevation: 0,
      titleSpacing: 28,
      title: Row(
        children: [
          Icon(Icons.waves, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            'Survivor Pool',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          _buildDesktopUserChip(theme),
        ],
      ),
    );
  }

  Widget _buildMobileProfileAction(ThemeData theme) {
    final onPrimary = theme.colorScheme.onPrimary;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: _buildProfileButton(
        theme: theme,
        foreground: onPrimary,
        avatarBackground: onPrimary.withValues(alpha: 0.12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: BorderSide(color: onPrimary.withValues(alpha: 0.3)),
      ),
    );
  }

  Widget _buildDesktopUserChip(ThemeData theme) {
    final primary = theme.colorScheme.primary;
    return _buildProfileButton(
      theme: theme,
      foreground: primary,
      avatarBackground: primary.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      side: BorderSide(color: primary.withValues(alpha: 0.2)),
    );
  }

  Widget _buildProfileButton({
    required ThemeData theme,
    required Color foreground,
    required Color avatarBackground,
    required EdgeInsetsGeometry padding,
    BorderSide? side,
  }) {
    final displayName = widget.user.displayName.trim();
    final username = widget.user.username.trim();
    final email = widget.user.email.trim();
    final label = displayName.isNotEmpty
        ? displayName
        : (username.isNotEmpty ? username : email);
    final initialSource = displayName.isNotEmpty
        ? displayName
        : (username.isNotEmpty ? username : email);
    final initial = initialSource.isNotEmpty
        ? initialSource[0].toUpperCase()
        : '?';

    return OutlinedButton.icon(
      onPressed: _openProfile,
      icon: CircleAvatar(
        radius: 16,
        backgroundColor: avatarBackground,
        child: Text(
          initial,
          style: theme.textTheme.labelLarge?.copyWith(color: foreground),
        ),
      ),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: foreground,
        padding: padding,
        side: side,
        shape: const StadiumBorder(),
        textStyle: theme.textTheme.labelLarge,
      ),
    );
  }

  Widget _buildDesktopBody({
    required ThemeData theme,
    required PoolOption? selectedPool,
    required bool isOwnerView,
    required List<AvailableContestant> availableContestants,
    required bool isLoadingContestants,
    required CurrentPickSummary? currentPick,
    required int? score,
    required bool showInvites,
  }) {
    return SafeArea(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 320,
            child: _buildDesktopSidebar(
              theme: theme,
              showInvites: showInvites,
              selectedPool: selectedPool,
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: PlatformRefresh(
              onRefresh: kIsWeb ? null : _refreshHome,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: AdaptivePage(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildMainSection(
                        theme: theme,
                        selectedPool: selectedPool,
                        isOwnerView: isOwnerView,
                        availableContestants: availableContestants,
                        isLoadingContestants: isLoadingContestants,
                        currentPick: currentPick,
                        score: score,
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar({
    required ThemeData theme,
    required bool showInvites,
    required PoolOption? selectedPool,
  }) {
    final items = <Widget>[];

    items.add(_buildPoolListCard(theme, selectedPool));
    items.add(const SizedBox(height: 16));
    items.add(_buildInvitesBanner(theme));

    return Container(
      color: theme.colorScheme.surface,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        children: items,
      ),
    );
  }

  Widget _buildPoolListCard(ThemeData theme, PoolOption? selectedPool) {
    final selectedId = selectedPool?.id;
    final pools = _pools;
    final isBusy = _isUpdatingDefault || _isLoadingPools;

    Widget buildTile({
      required String label,
      required bool selected,
      String? subtitle,
      VoidCallback? onTap,
    }) {
      final background = selected
          ? theme.colorScheme.primary.withAlpha(30)
          : theme.colorScheme.surface;
      final titleStyle = theme.textTheme.titleMedium?.copyWith(
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface,
      );
      final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.8)
            : theme.colorScheme.onSurfaceVariant,
      );

      return InkWell(
        onTap: (selected || isBusy) ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: titleStyle),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(subtitle, style: subtitleStyle),
              ],
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Your pools',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isLoadingPools) ...[
                  const SizedBox(width: 12),
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
                const Spacer(),
                FilledButton.icon(
                  onPressed: _isLoadingSeasons ? null : _showCreatePoolDialog,
                  icon: _isLoadingSeasons
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_circle_outline),
                  label: Text(_isLoadingSeasons ? 'Loading...' : 'New pool'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (pools.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'No pools yet. Create one to get started.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else ...[
              for (var i = 0; i < pools.length; i++) ...[
                buildTile(
                  label: pools[i].name,
                  selected: pools[i].id == selectedId,
                  subtitle: 'Week ${pools[i].currentWeek}',
                  onTap: () => _updateDefaultPool(pools[i].id),
                ),
                if (i != pools.length - 1) const SizedBox(height: 8),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMobileBody({
    required ThemeData theme,
    required PoolOption? selectedPool,
    required bool isOwnerView,
    required List<AvailableContestant> availableContestants,
    required bool isLoadingContestants,
    required CurrentPickSummary? currentPick,
    required int? score,
    required bool showInvites,
  }) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          score: score,
        ),
      ],
    );

    final listView = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [content],
    );

    return SafeArea(
      child: PlatformRefresh(
        onRefresh: kIsWeb ? null : _refreshHome,
        child: listView,
      ),
    );
  }

  void _openProfile() {
    Navigator.of(context).pushNamed(AppRoutes.profile, arguments: widget.user);
  }

  Widget _buildMainSection({
    required ThemeData theme,
    required PoolOption? selectedPool,
    required bool isOwnerView,
    required List<AvailableContestant> availableContestants,
    required bool isLoadingContestants,
    required CurrentPickSummary? currentPick,
    required int? score,
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
        score: score,
        isEliminated: _isEliminated,
        eliminationReason: _eliminationReason,
        eliminatedWeek: _eliminatedWeek,
        isWinner: _isWinner,
        poolStatus: _poolStatus,
        poolCompletedWeek: _poolCompletedWeek,
        poolCompletedAt: _poolCompletedAt,
        winners: _winners,
        didTie: _didTie,
        onManageMembers: isOwnerView
            ? () => _handleManageMembers(selectedPool)
            : null,
        onManageSettings: isOwnerView
            ? () => _handlePoolSettings(selectedPool)
            : null,
        onAdvanceWeek: isOwnerView && _poolStatus != 'completed'
            ? () => _handleAdvanceWeek(selectedPool)
            : null,
        onViewLeaderboard: () => _handleViewLeaderboard(selectedPool),
        onContestantSelected:
            _isEliminated || _isWinner || _poolStatus == 'completed'
            ? null
            : (contestant) {
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
                  ? 'No pools yet. Create one to get started.'
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
            if (_pendingInvites.isEmpty)
              Text(
                'No pending invites right now.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ..._pendingInvites.map(
                (invite) => _buildInviteRow(theme, invite),
              ),
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
      fontWeight: FontWeight.w500,
    );

    Widget buildPoolItem(PoolOption pool) {
      final isSelected = pool.id == selectedPoolId;
      final baseStyle =
          textStyle ?? theme.textTheme.bodyMedium ?? const TextStyle();
      final labelStyle = baseStyle.copyWith(
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        color: isSelected ? theme.colorScheme.primary : baseStyle.color,
      );

      return MenuItemButton(
        onPressed: () {
          _updateDefaultPool(pool.id);
        },
        child: SizedBox(
          width: 200,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              pool.name,
              overflow: TextOverflow.ellipsis,
              style: labelStyle,
            ),
          ),
        ),
      );
    }

    final canCreatePool = !_isLoadingSeasons;

    final menuChildren = <Widget>[
      ..._pools.map(buildPoolItem),
      MenuItemButton(
        onPressed: canCreatePool ? _showCreatePoolDialog : null,
        child: SizedBox(
          width: 200,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 20,
                  color: canCreatePool
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Create new pool',
                    style: textStyle ?? theme.textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ];

    return MenuAnchor(
      builder: (context, controller, child) {
        final isBusy = _isUpdatingDefault || _isLoadingPools;
        return IconButton(
          icon: const Icon(Icons.home_outlined),
          color: Colors.white,
          onPressed: isBusy
              ? null
              : () {
                  controller.isOpen ? controller.close() : controller.open();
                },
        );
      },
      menuChildren: menuChildren,
    );
  }
}
