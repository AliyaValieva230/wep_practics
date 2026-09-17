import '../core/role.dart';

class AppUser {
  final int id;
  final String username;
  final String fullName;
  final Role role;

  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as int? ?? 0,
        username: json['username'] as String? ?? '',
        fullName:
            (json['fullName'] ?? json['name'] ?? json['username']) as String? ??
                '',
        role: Role.fromWire(json['role'] as String?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'fullName': fullName,
        'role': role.name.toUpperCase(),
      };
}

class AuthResult {
  final String accessToken;
  final String refreshToken;
  final AppUser user;

  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        accessToken: (json['accessToken'] ?? json['access_token']) as String,
        refreshToken: (json['refreshToken'] ?? json['refresh_token']) as String,
        user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}
