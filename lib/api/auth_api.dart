import 'package:b_flutter/common/app_environment.dart';
import 'package:b_flutter/models/generated_account.dart';
import 'package:b_flutter/models/user_session.dart';
import 'package:b_flutter/utils/api_client.dart';

abstract final class AuthApi {
  static Future<UserSession> login({
    required String username,
    required String password,
    String googleCode = '',
    bool lock = true,
    String lockText = '登录中...',
  }) {
    return ApiClient().post<UserSession>(
      'api/logins',
      data: <String, Object?>{
        'username': username,
        'password': password,
        'code': googleCode,
      },
      parser: _parseSession,
      lock: lock,
      lockText: lockText,
      showErrorToast: true,
    );
  }

  static Future<UserSession> register({
    required String nickname,
    required String username,
    required String password,
    required String birthday,
    bool lock = true,
    String lockText = '注册中...',
  }) {
    return ApiClient().post<UserSession>(
      'api/registers',
      data: <String, Object?>{
        'nickname': nickname,
        'username': username,
        'password': password,
        'channel': AppEnvironment.channel,
        'birthday': birthday,
      },
      parser: _parseSession,
      lock: lock,
      lockText: lockText,
      showErrorToast: true,
    );
  }

  static Future<GeneratedAccount> generateAccount({
    bool lock = true,
    String lockText = '正在生成账号...',
  }) {
    return ApiClient().get<GeneratedAccount>(
      'api/generates',
      parser: (data) {
        if (data is! Map) throw const FormatException('Invalid account');
        return GeneratedAccount.fromJson(Map<String, dynamic>.from(data));
      },
      lock: lock,
      lockText: lockText,
      showErrorToast: true,
      deduplicate: false,
    );
  }

  static Future<void> recoverPassword({
    required String username,
    required String birthday,
    required String newPassword,
    required String confirmPassword,
    bool lock = true,
    String lockText = '正在重置密码...',
  }) {
    return ApiClient().post<void>(
      'api/recoverPasswords',
      data: <String, Object?>{
        'username': username,
        'birthday': birthday,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      },
      parser: (_) {},
      lock: lock,
      lockText: lockText,
      showErrorToast: true,
    );
  }

  static Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
    bool lock = true,
    String lockText = '提交中...',
  }) {
    return ApiClient().post<void>(
      'api/updatePasswords',
      data: <String, Object?>{
        'old_password': oldPassword,
        'password': newPassword,
        're_password': confirmPassword,
      },
      parser: (_) {},
      lock: lock,
      lockText: lockText,
      showErrorToast: true,
    );
  }

  static UserSession _parseSession(Object? data) {
    if (data is! Map) throw const FormatException('Invalid user session');
    final session = UserSession.fromJson(Map<String, dynamic>.from(data));
    if (session.token.isEmpty) throw const FormatException('Missing token');
    return session;
  }
}
