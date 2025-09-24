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
}
