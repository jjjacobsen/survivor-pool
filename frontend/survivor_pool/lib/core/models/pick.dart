class CurrentPickSummary {
  final String id;
  final String contestantId;
  final String contestantName;
  final int week;
  final DateTime lockedAt;

  const CurrentPickSummary({
    required this.id,
    required this.contestantId,
    required this.contestantName,
    required this.week,
    required this.lockedAt,
  });

  factory CurrentPickSummary.fromJson(Map<String, dynamic> json) {
    final id = json['pick_id'] as String? ?? json['id'] as String? ?? '';
    final contestantId = json['contestant_id'] as String? ?? '';
    final contestantName = json['contestant_name'] as String? ?? contestantId;
    final rawWeek = json['week'];
    final rawLocked = json['locked_at'];
    var parsedWeek = 0;
    if (rawWeek is int) {
      parsedWeek = rawWeek;
    } else if (rawWeek is num) {
      parsedWeek = rawWeek.toInt();
    } else if (rawWeek is String) {
      parsedWeek = int.tryParse(rawWeek) ?? 0;
    }
    DateTime lockedAt;
    if (rawLocked is String) {
      lockedAt = DateTime.tryParse(rawLocked) ?? DateTime.now();
    } else if (rawLocked is int) {
      lockedAt = DateTime.fromMillisecondsSinceEpoch(rawLocked);
    } else if (rawLocked is num) {
      lockedAt = DateTime.fromMillisecondsSinceEpoch(rawLocked.toInt());
    } else if (rawLocked is DateTime) {
      lockedAt = rawLocked;
    } else {
      lockedAt = DateTime.now();
    }

    return CurrentPickSummary(
      id: id,
      contestantId: contestantId,
      contestantName: contestantName.isEmpty ? contestantId : contestantName,
      week: parsedWeek,
      lockedAt: lockedAt,
    );
  }
}

class PickResponse {
  final String id;
  final String contestantId;
  final int week;
  final DateTime lockedAt;

  const PickResponse({
    required this.id,
    required this.contestantId,
    required this.week,
    required this.lockedAt,
  });

  factory PickResponse.fromJson(Map<String, dynamic> json) {
    final rawLocked = json['locked_at'];
    DateTime lockedAt;
    if (rawLocked is String) {
      lockedAt = DateTime.tryParse(rawLocked) ?? DateTime.now();
    } else if (rawLocked is int) {
      lockedAt = DateTime.fromMillisecondsSinceEpoch(rawLocked);
    } else if (rawLocked is num) {
      lockedAt = DateTime.fromMillisecondsSinceEpoch(rawLocked.toInt());
    } else if (rawLocked is DateTime) {
      lockedAt = rawLocked;
    } else {
      lockedAt = DateTime.now();
    }

    final rawWeek = json['week'];
    var parsedWeek = 0;
    if (rawWeek is int) {
      parsedWeek = rawWeek;
    } else if (rawWeek is num) {
      parsedWeek = rawWeek.toInt();
    } else if (rawWeek is String) {
      parsedWeek = int.tryParse(rawWeek) ?? 0;
    }

    final id = json['pick_id'] as String? ?? json['id'] as String? ?? '';

    return PickResponse(
      id: id,
      contestantId: json['contestant_id'] as String? ?? '',
      week: parsedWeek,
      lockedAt: lockedAt,
    );
  }
}
