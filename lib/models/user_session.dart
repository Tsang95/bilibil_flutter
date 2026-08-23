import 'package:b_flutter/models/user_info.dart';

final class UserSession {
  const UserSession({required this.token, required this.user});

  factory UserSession.fromJson(Map<String, dynamic> json) {
    final rawUser = json['member'];
    if (rawUser is! Map) throw const FormatException('Invalid user session');
    return UserSession(
      token: json['token']?.toString() ?? '',
      user: UserInfo.fromJson(Map<String, dynamic>.from(rawUser)),
    );
  }

  final String token;
  final UserInfo user;
}
