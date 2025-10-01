class PoolAdvanceMissingMember {
  final String userId;
  final String displayName;

  const PoolAdvanceMissingMember({
    required this.userId,
    required this.displayName,
  });

  factory PoolAdvanceMissingMember.fromJson(Map<String, dynamic> json) {
    final userId = json['user_id'] as String? ?? '';
    final displayName = json['display_name'] as String? ?? '';
    return PoolAdvanceMissingMember(
      userId: userId,
      displayName: displayName.isNotEmpty ? displayName : userId,
    );
  }
}

class PoolAdvanceStatus {
  final int currentWeek;
  final int activeMemberCount;
  final int lockedCount;
  final int missingCount;
  final List<PoolAdvanceMissingMember> missingMembers;

  const PoolAdvanceStatus({
    required this.currentWeek,
    required this.activeMemberCount,
    required this.lockedCount,
    required this.missingCount,
    required this.missingMembers,
  });

  factory PoolAdvanceStatus.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
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

    final members = json['missing_members'];
    final parsedMembers = members is List
        ? members
              .whereType<Map<String, dynamic>>()
              .map(PoolAdvanceMissingMember.fromJson)
              .where((member) => member.userId.isNotEmpty)
              .toList()
        : <PoolAdvanceMissingMember>[];

    parsedMembers.sort(
      (a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
    );

    final week = parseInt(json['current_week']);

    return PoolAdvanceStatus(
      currentWeek: week <= 0 ? 1 : week,
      activeMemberCount: parseInt(json['active_member_count']),
      lockedCount: parseInt(json['locked_count']),
      missingCount: parseInt(json['missing_count']),
      missingMembers: parsedMembers,
    );
  }
}

class PoolAdvanceElimination {
  final String userId;
  final String displayName;
  final String reason;

  const PoolAdvanceElimination({
    required this.userId,
    required this.displayName,
    required this.reason,
  });

  factory PoolAdvanceElimination.fromJson(Map<String, dynamic> json) {
    final userId = json['user_id'] as String? ?? '';
    final displayName = json['display_name'] as String? ?? '';
    final reason = json['reason'] as String? ?? ''; // fall back to empty string
    return PoolAdvanceElimination(
      userId: userId,
      displayName: displayName.isNotEmpty ? displayName : userId,
      reason: reason,
    );
  }
}
