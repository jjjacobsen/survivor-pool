class PoolAdvanceMissingMember {
  final String userId;
  final String username;

  const PoolAdvanceMissingMember({
    required this.userId,
    required this.username,
  });

  factory PoolAdvanceMissingMember.fromJson(Map<String, dynamic> json) {
    final userId = json['user_id'] as String? ?? '';
    final username = json['username'] as String? ?? '';
    return PoolAdvanceMissingMember(
      userId: userId,
      username: username.isNotEmpty ? username : userId,
    );
  }
}

class PoolAdvanceStatus {
  final int currentWeek;
  final int activeMemberCount;
  final int lockedCount;
  final int missingCount;
  final List<PoolAdvanceMissingMember> missingMembers;
  final bool canAdvance;

  const PoolAdvanceStatus({
    required this.currentWeek,
    required this.activeMemberCount,
    required this.lockedCount,
    required this.missingCount,
    required this.missingMembers,
    required this.canAdvance,
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
      (a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()),
    );

    final week = parseInt(json['current_week']);
    final canAdvance = json['can_advance'] == true;

    return PoolAdvanceStatus(
      currentWeek: week <= 0 ? 1 : week,
      activeMemberCount: parseInt(json['active_member_count']),
      lockedCount: parseInt(json['locked_count']),
      missingCount: parseInt(json['missing_count']),
      missingMembers: parsedMembers,
      canAdvance: canAdvance,
    );
  }
}

class PoolAdvanceElimination {
  final String userId;
  final String username;
  final String reason;

  const PoolAdvanceElimination({
    required this.userId,
    required this.username,
    required this.reason,
  });

  factory PoolAdvanceElimination.fromJson(Map<String, dynamic> json) {
    final userId = json['user_id'] as String? ?? '';
    final username = json['username'] as String? ?? '';
    final reason = json['reason'] as String? ?? ''; // fall back to empty string
    return PoolAdvanceElimination(
      userId: userId,
      username: username.isNotEmpty ? username : userId,
      reason: reason,
    );
  }
}
