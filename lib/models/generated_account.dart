final class GeneratedAccount {
  const GeneratedAccount({
    required this.nickname,
    required this.username,
    required this.password,
  });

  factory GeneratedAccount.fromJson(Map<String, dynamic> json) {
    return GeneratedAccount(
      nickname: json['nickname']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
    );
  }

  final String nickname;
  final String username;
  final String password;
}
