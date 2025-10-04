import 'package:survivor_pool/core/models/pool.dart';

DateTime? _parseIsoDate(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

int? _parseInt(dynamic value) {
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

class PoolLeaderboardEntry {
  final int rank;
  final String userId;
  final String displayName;
  final int score;
  final String status;
  final bool isWinner;
  final String? eliminationReason;
  final int? eliminatedWeek;
  final int? finalRank;
  final int? finishedWeek;
  final DateTime? finishedDate;

  const PoolLeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.score,
    required this.status,
    required this.isWinner,
    this.eliminationReason,
    this.eliminatedWeek,
    this.finalRank,
    this.finishedWeek,
    this.finishedDate,
  });

  factory PoolLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return PoolLeaderboardEntry(
      rank: _parseInt(json['rank']) ?? 0,
      userId: json['user_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      score: _parseInt(json['score']) ?? 0,
      status: json['status'] as String? ?? 'active',
      isWinner: json['is_winner'] == true,
      eliminationReason: json['elimination_reason'] as String?,
      eliminatedWeek: _parseInt(json['eliminated_week']),
      finalRank: _parseInt(json['final_rank']),
      finishedWeek: _parseInt(json['finished_week']),
      finishedDate: _parseIsoDate(json['finished_date']),
    );
  }
}

class PoolLeaderboard {
  final String poolId;
  final int currentWeek;
  final String poolStatus;
  final int? poolCompletedWeek;
  final DateTime? poolCompletedAt;
  final List<PoolLeaderboardEntry> entries;
  final List<PoolWinner> winners;
  final bool didTie;

  const PoolLeaderboard({
    required this.poolId,
    required this.currentWeek,
    required this.poolStatus,
    required this.poolCompletedWeek,
    required this.poolCompletedAt,
    required this.entries,
    required this.winners,
    required this.didTie,
  });

  factory PoolLeaderboard.fromJson(Map<String, dynamic> json) {
    final entriesData = json['entries'];
    final winnersData = json['winners'];
    return PoolLeaderboard(
      poolId: json['pool_id'] as String? ?? '',
      currentWeek: _parseInt(json['current_week']) ?? 1,
      poolStatus: json['pool_status'] as String? ?? 'open',
      poolCompletedWeek: _parseInt(json['pool_completed_week']),
      poolCompletedAt: _parseIsoDate(json['pool_completed_at']),
      entries: entriesData is List
          ? entriesData
                .whereType<Map<String, dynamic>>()
                .map(PoolLeaderboardEntry.fromJson)
                .where((entry) => entry.userId.isNotEmpty)
                .toList(growable: false)
          : const <PoolLeaderboardEntry>[],
      winners: winnersData is List
          ? winnersData
                .whereType<Map<String, dynamic>>()
                .map(PoolWinner.fromJson)
                .where((winner) => winner.userId.isNotEmpty)
                .toList(growable: false)
          : const <PoolWinner>[],
      didTie: json['did_tie'] == true,
    );
  }

  bool get isCompleted => poolStatus == 'completed';
}
