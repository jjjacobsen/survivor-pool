class PoolOption {
  final String id;
  final String name;
  final String seasonId;
  final String? ownerId;
  final int? seasonNumber;
  final int currentWeek;
  final int startWeek;
  final String status;
  final bool isCompetitive;
  final int? competitiveSinceWeek;
  final int? completedWeek;
  final DateTime? completedAt;
  final List<String> winnerUserIds;

  const PoolOption({
    required this.id,
    required this.name,
    required this.seasonId,
    this.ownerId,
    this.seasonNumber,
    this.currentWeek = 1,
    this.startWeek = 1,
    this.status = 'open',
    this.isCompetitive = false,
    this.competitiveSinceWeek,
    this.completedWeek,
    this.completedAt,
    this.winnerUserIds = const <String>[],
  });

  factory PoolOption.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['_id'];
    final seasonId = json['season_id'] ?? json['seasonId'] ?? '';
    final ownerId = json['owner_id'] ?? json['ownerId'];
    final dynamicSeasonNumber = json['season_number'] ?? json['seasonNumber'];
    final dynamicCurrentWeek = json['current_week'] ?? json['currentWeek'];
    final dynamicStartWeek = json['start_week'] ?? json['startWeek'];
    int? parsedSeasonNumber;
    if (dynamicSeasonNumber is int) {
      parsedSeasonNumber = dynamicSeasonNumber;
    } else if (dynamicSeasonNumber is num) {
      parsedSeasonNumber = dynamicSeasonNumber.toInt();
    } else if (dynamicSeasonNumber is String) {
      parsedSeasonNumber = int.tryParse(dynamicSeasonNumber);
    }
    var parsedCurrentWeek = 1;
    if (dynamicCurrentWeek is int) {
      parsedCurrentWeek = dynamicCurrentWeek;
    } else if (dynamicCurrentWeek is num) {
      parsedCurrentWeek = dynamicCurrentWeek.toInt();
    } else if (dynamicCurrentWeek is String) {
      parsedCurrentWeek = int.tryParse(dynamicCurrentWeek) ?? 1;
    }
    var parsedStartWeek = 1;
    if (dynamicStartWeek is int) {
      parsedStartWeek = dynamicStartWeek;
    } else if (dynamicStartWeek is num) {
      parsedStartWeek = dynamicStartWeek.toInt();
    } else if (dynamicStartWeek is String) {
      parsedStartWeek = int.tryParse(dynamicStartWeek) ?? 1;
    }
    if (parsedStartWeek < 1) {
      parsedStartWeek = 1;
    }
    final statusRaw = json['status'];
    final status = statusRaw is String && statusRaw.isNotEmpty
        ? statusRaw
        : 'open';
    final isCompetitiveValue = json['is_competitive'];
    final isCompetitive = isCompetitiveValue is bool
        ? isCompetitiveValue
        : (isCompetitiveValue == 'true');
    int? parseInt(dynamic value) {
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

    final competitiveSinceWeek = parseInt(
      json['competitive_since_week'] ?? json['competitiveSinceWeek'],
    );
    final completedWeek = parseInt(
      json['completed_week'] ?? json['completedWeek'],
    );
    final completedAt = _parseIsoDate(
      json['completed_at'] ?? json['completedAt'],
    );
    final winnersRaw = json['winner_user_ids'] ?? json['winnerUserIds'];
    final winnerUserIds = winnersRaw is List
        ? winnersRaw.whereType<String>().where((id) => id.isNotEmpty).toList()
        : <String>[];
    return PoolOption(
      id: (rawId as String?) ?? '',
      name: json['name'] as String? ?? 'Untitled Pool',
      seasonId: (seasonId as String?) ?? '',
      ownerId: ownerId is String ? ownerId : null,
      seasonNumber: parsedSeasonNumber,
      currentWeek: parsedCurrentWeek,
      startWeek: parsedStartWeek,
      status: status,
      isCompetitive: isCompetitive,
      competitiveSinceWeek: competitiveSinceWeek,
      completedWeek: completedWeek,
      completedAt: completedAt,
      winnerUserIds: winnerUserIds,
    );
  }

  PoolOption copyWith({
    String? id,
    String? name,
    String? seasonId,
    String? ownerId,
    int? seasonNumber,
    int? currentWeek,
    int? startWeek,
    String? status,
    bool? isCompetitive,
    int? competitiveSinceWeek,
    int? completedWeek,
    DateTime? completedAt,
    List<String>? winnerUserIds,
  }) {
    return PoolOption(
      id: id ?? this.id,
      name: name ?? this.name,
      seasonId: seasonId ?? this.seasonId,
      ownerId: ownerId ?? this.ownerId,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      currentWeek: currentWeek ?? this.currentWeek,
      startWeek: startWeek ?? this.startWeek,
      status: status ?? this.status,
      isCompetitive: isCompetitive ?? this.isCompetitive,
      competitiveSinceWeek: competitiveSinceWeek ?? this.competitiveSinceWeek,
      completedWeek: completedWeek ?? this.completedWeek,
      completedAt: completedAt ?? this.completedAt,
      winnerUserIds: winnerUserIds ?? this.winnerUserIds,
    );
  }
}

DateTime? _parseIsoDate(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

class PoolWinner {
  final String userId;
  final String displayName;

  const PoolWinner({required this.userId, required this.displayName});

  factory PoolWinner.fromJson(Map<String, dynamic> json) {
    final userId = json['user_id'] as String? ?? '';
    final displayName = json['display_name'] as String? ?? '';
    return PoolWinner(
      userId: userId,
      displayName: displayName.isNotEmpty ? displayName : userId,
    );
  }
}

class PoolMemberSummary {
  final String userId;
  final String displayName;
  final String email;
  final String role;
  final String status;
  final DateTime? joinedAt;
  final DateTime? invitedAt;
  final String? eliminationReason;
  final int? eliminatedWeek;
  final DateTime? eliminatedDate;
  final int? finalRank;
  final int? finishedWeek;
  final DateTime? finishedDate;

  const PoolMemberSummary({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.role,
    required this.status,
    this.joinedAt,
    this.invitedAt,
    this.eliminationReason,
    this.eliminatedWeek,
    this.eliminatedDate,
    this.finalRank,
    this.finishedWeek,
    this.finishedDate,
  });

  factory PoolMemberSummary.fromJson(Map<String, dynamic> json) {
    int? parseWeek(dynamic value) {
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

    return PoolMemberSummary(
      userId: json['user_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'member',
      status: json['status'] as String? ?? 'active',
      joinedAt: _parseIsoDate(json['joined_at']),
      invitedAt: _parseIsoDate(json['invited_at']),
      eliminationReason: json['elimination_reason'] as String?,
      eliminatedWeek: parseWeek(json['eliminated_week']),
      eliminatedDate: _parseIsoDate(json['eliminated_date']),
      finalRank: parseWeek(json['final_rank']),
      finishedWeek: parseWeek(json['finished_week']),
      finishedDate: _parseIsoDate(json['finished_date']),
    );
  }

  bool get isPending => status == 'invited';
}

class PoolMembershipList {
  final String poolId;
  final List<PoolMemberSummary> members;

  const PoolMembershipList({required this.poolId, required this.members});

  factory PoolMembershipList.fromJson(Map<String, dynamic> json) {
    final poolId = json['pool_id'] as String? ?? '';
    final data = json['members'];
    final members = data is List
        ? data
              .whereType<Map<String, dynamic>>()
              .map(PoolMemberSummary.fromJson)
              .where((member) => member.userId.isNotEmpty)
              .toList()
        : <PoolMemberSummary>[];
    return PoolMembershipList(poolId: poolId, members: members);
  }
}

class PendingInvite {
  final String poolId;
  final String poolName;
  final String ownerDisplayName;
  final String seasonId;
  final int? seasonNumber;
  final DateTime? invitedAt;

  const PendingInvite({
    required this.poolId,
    required this.poolName,
    required this.ownerDisplayName,
    required this.seasonId,
    this.seasonNumber,
    this.invitedAt,
  });

  factory PendingInvite.fromJson(Map<String, dynamic> json) {
    return PendingInvite(
      poolId: json['pool_id'] as String? ?? '',
      poolName: json['pool_name'] as String? ?? '',
      ownerDisplayName: json['owner_display_name'] as String? ?? '',
      seasonId: json['season_id'] as String? ?? '',
      seasonNumber: json['season_number'] is int
          ? json['season_number'] as int
          : (json['season_number'] is num
                ? (json['season_number'] as num).toInt()
                : null),
      invitedAt: _parseIsoDate(json['invited_at']),
    );
  }
}
