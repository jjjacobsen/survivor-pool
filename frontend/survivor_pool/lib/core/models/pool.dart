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
