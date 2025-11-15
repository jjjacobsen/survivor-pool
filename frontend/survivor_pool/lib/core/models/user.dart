class AppUser {
  final String id;
  final String username;
  final String email;
  final String? defaultPoolId;

  const AppUser({
    required this.id,
    required this.username,
    required this.email,
    this.defaultPoolId,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      defaultPoolId: json['default_pool'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'default_pool': defaultPoolId,
    };
  }
}

class UserSearchResult {
  final String id;
  final String email;
  final String username;
  final String? membershipStatus;

  const UserSearchResult({
    required this.id,
    required this.email,
    required this.username,
    this.membershipStatus,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      membershipStatus: json['membership_status'] as String?,
    );
  }
}
