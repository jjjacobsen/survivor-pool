class PoolOption {
  final String id;
  final String name;
  final String seasonId;
  final String? ownerId;
  final int? seasonNumber;
  final int currentWeek;

  const PoolOption({
    required this.id,
    required this.name,
    required this.seasonId,
    this.ownerId,
    this.seasonNumber,
    this.currentWeek = 1,
  });

  factory PoolOption.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['_id'];
    final seasonId = json['season_id'] ?? json['seasonId'] ?? '';
    final ownerId = json['owner_id'] ?? json['ownerId'];
    final dynamicSeasonNumber = json['season_number'] ?? json['seasonNumber'];
    final dynamicCurrentWeek = json['current_week'] ?? json['currentWeek'];
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
    return PoolOption(
      id: (rawId as String?) ?? '',
      name: json['name'] as String? ?? 'Untitled Pool',
      seasonId: (seasonId as String?) ?? '',
      ownerId: ownerId is String ? ownerId : null,
      seasonNumber: parsedSeasonNumber,
      currentWeek: parsedCurrentWeek,
    );
  }

  PoolOption copyWith({
    String? id,
    String? name,
    String? seasonId,
    String? ownerId,
    int? seasonNumber,
    int? currentWeek,
  }) {
    return PoolOption(
      id: id ?? this.id,
      name: name ?? this.name,
      seasonId: seasonId ?? this.seasonId,
      ownerId: ownerId ?? this.ownerId,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      currentWeek: currentWeek ?? this.currentWeek,
    );
  }
}

DateTime? _parseIsoDate(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

class PoolMemberSummary {
  final String userId;
  final String displayName;
  final String email;
  final String role;
  final String status;
  final DateTime? joinedAt;
  final DateTime? invitedAt;

  const PoolMemberSummary({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.role,
    required this.status,
    this.joinedAt,
    this.invitedAt,
  });

  factory PoolMemberSummary.fromJson(Map<String, dynamic> json) {
    return PoolMemberSummary(
      userId: json['user_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'member',
      status: json['status'] as String? ?? 'active',
      joinedAt: _parseIsoDate(json['joined_at']),
      invitedAt: _parseIsoDate(json['invited_at']),
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
