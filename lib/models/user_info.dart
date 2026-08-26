final class UserInfo {
  const UserInfo({
    required this.id,
    required this.username,
    required this.nickname,
    required this.avatarUrl,
    required this.signature,
    required this.backgroundUrl,
    required this.gender,
    required this.movieVipLevel,
    required this.movieVipExpiresAt,
    required this.mediaType,
    required this.mediaVipExpiresAt,
    required this.goldBalance,
    required this.blockedBalance,
    required this.buyCount,
    required this.collectCount,
    required this.followCount,
    required this.fansCount,
    required this.coinCount,
    required this.mediaPostCount,
    required this.likeMessageCount,
    required this.commentMessageCount,
    required this.messageCount,
    required this.invitationCode,
    this.hasPayPassword = false,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: _integer(json['id']),
      username: _string(json['username']),
      nickname: _string(json['nickname']),
      avatarUrl: _string(json['head_sculpture']),
      signature: _string(json['sign']),
      backgroundUrl: _string(json['background']),
      gender: _integer(json['gender']),
      movieVipLevel: _integer(json['movie_vip_level']),
      movieVipExpiresAt: _dateTime(json['movie_vip_time']),
      mediaType: _integer(json['media_type']),
      mediaVipExpiresAt: _dateTime(json['media_vip_time']),
      goldBalance: _number(json['gold_balance']),
      blockedBalance: _number(json['blocked_balance']),
      buyCount: _integer(json['buy_num']),
      collectCount: _integer(json['collect_num']),
      followCount: _integer(json['focus_num']),
      fansCount: _integer(json['fans_num']),
      coinCount: _integer(json['coin_num']),
      mediaPostCount: _integer(json['media_post_num']),
      likeMessageCount: _integer(json['like_msg_num']),
      commentMessageCount: _integer(json['comment_msg_num']),
      messageCount: _integer(json['msg_num']),
      invitationCode: _string(json['invitation_code']),
      hasPayPassword: _integer(json['pay_pwd']) != 0,
    );
  }

  final int id;
  final String username;
  final String nickname;
  final String avatarUrl;
  final String signature;
  final String backgroundUrl;
  final int gender;
  final int movieVipLevel;
  final DateTime? movieVipExpiresAt;
  final int mediaType;
  final DateTime? mediaVipExpiresAt;
  final double goldBalance;
  final double blockedBalance;
  final int buyCount;
  final int collectCount;
  final int followCount;
  final int fansCount;
  final int coinCount;
  final int mediaPostCount;
  final int likeMessageCount;
  final int commentMessageCount;
  final int messageCount;
  final String invitationCode;
  final bool hasPayPassword;

  bool get isVideoVip {
    final expiresAt = movieVipExpiresAt;
    return expiresAt != null && DateTime.now().isBefore(expiresAt);
  }

  bool get isCreatorVip {
    final expiresAt = mediaVipExpiresAt;
    return expiresAt != null && DateTime.now().isBefore(expiresAt);
  }

  int get totalInteractionMessages {
    final total = likeMessageCount + commentMessageCount;
    return total > 99 ? 99 : total;
  }

  UserInfo copyWith({
    String? nickname,
    String? avatarUrl,
    String? signature,
    String? backgroundUrl,
    int? gender,
    int? likeMessageCount,
    int? commentMessageCount,
    int? messageCount,
    bool? hasPayPassword,
  }) => UserInfo(
    id: id,
    username: username,
    nickname: nickname ?? this.nickname,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    signature: signature ?? this.signature,
    backgroundUrl: backgroundUrl ?? this.backgroundUrl,
    gender: gender ?? this.gender,
    movieVipLevel: movieVipLevel,
    movieVipExpiresAt: movieVipExpiresAt,
    mediaType: mediaType,
    mediaVipExpiresAt: mediaVipExpiresAt,
    goldBalance: goldBalance,
    blockedBalance: blockedBalance,
    buyCount: buyCount,
    collectCount: collectCount,
    followCount: followCount,
    fansCount: fansCount,
    coinCount: coinCount,
    mediaPostCount: mediaPostCount,
    likeMessageCount: likeMessageCount ?? this.likeMessageCount,
    commentMessageCount: commentMessageCount ?? this.commentMessageCount,
    messageCount: messageCount ?? this.messageCount,
    invitationCode: invitationCode,
    hasPayPassword: hasPayPassword ?? this.hasPayPassword,
  );

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'username': username,
      'nickname': nickname,
      'head_sculpture': avatarUrl,
      'sign': signature,
      'background': backgroundUrl,
      'gender': gender,
      'movie_vip_level': movieVipLevel,
      'movie_vip_time': movieVipExpiresAt?.toIso8601String(),
      'media_type': mediaType,
      'media_vip_time': mediaVipExpiresAt?.toIso8601String(),
      'gold_balance': goldBalance,
      'blocked_balance': blockedBalance,
      'buy_num': buyCount,
      'collect_num': collectCount,
      'focus_num': followCount,
      'fans_num': fansCount,
      'coin_num': coinCount,
      'media_post_num': mediaPostCount,
      'like_msg_num': likeMessageCount,
      'comment_msg_num': commentMessageCount,
      'msg_num': messageCount,
      'invitation_code': invitationCode,
      'pay_pwd': hasPayPassword ? 1 : 0,
    };
  }

  static String _string(Object? value) => value?.toString() ?? '';

  static int _integer(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _number(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _dateTime(Object? value) {
    final rawValue = value?.toString() ?? '';
    return rawValue.isEmpty ? null : DateTime.tryParse(rawValue);
  }
}
