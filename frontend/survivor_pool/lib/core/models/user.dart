class AppUser {
  final String id;
  final String username;
  final String email;
  final String displayName;
  final String? defaultPoolId;

  const AppUser({
    required this.id,
    required this.username,
    required this.email,
    required this.displayName,
    this.defaultPoolId,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final username = json['username'] as String? ?? '';
    final displayName = json['display_name'] as String?;
    return AppUser(
      id: json['id'] as String? ?? '',
      username: username,
      email: json['email'] as String? ?? '',
      displayName: (displayName != null && displayName.isNotEmpty)
          ? displayName
          : username,
      defaultPoolId: json['default_pool'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'display_name': displayName,
      'default_pool': defaultPoolId,
    };
  }
}

class UserSearchResult {
  final String id;
  final String displayName;
  final String email;
  final String username;
  final String? membershipStatus;

  const UserSearchResult({
    required this.id,
    required this.displayName,
    required this.email,
    required this.username,
    this.membershipStatus,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      membershipStatus: json['membership_status'] as String?,
    );
  }
}
