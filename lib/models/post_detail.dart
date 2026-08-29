final class PostDetail {
  const PostDetail({
    required this.id,
    required this.memberId,
    required this.primaryCategoryId,
    required this.type,
    required this.collectionType,
    required this.collectionId,
    required this.videoId,
    required this.durationSeconds,
    required this.title,
    required this.description,
    required this.htmlContent,
    required this.imageContent,
    required this.coverUrls,
    required this.horizontalCoverUrls,
    required this.secondaryCategoryName,
    required this.price,
    required this.salesCount,
    required this.viewCount,
    required this.collectCount,
    required this.likeCount,
    required this.coinCount,
    required this.downloadPrice,
    required this.hasDownloadAccess,
    required this.isPurchased,
    required this.unlockType,
    required this.jumpRegister,
    required this.isCollected,
    required this.isLiked,
    required this.hasTippedCoin,
    required this.shareUrl,
    required this.createdAt,
    required this.author,
    required this.labels,
    required this.videoChannels,
    required this.advertisements,
  });

  factory PostDetail.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'];
    final price = _number(json['price']);
    final isVipWatch = _integer(json['is_vip_watch']) == 1;
    final unlockType = json.containsKey('is_buy')
        ? _integer(json['is_buy'])
        : isVipWatch
            ? 2
            : price > 0
                ? 1
                : 0;
    return PostDetail(
      id: _integer(json['id']),
      memberId: _integer(json['member_id']),
      primaryCategoryId: _integer(json['plate_one_id']),
      type: _integer(json['type']),
      collectionType: _integer(json['collection_type']),
      collectionId: _string(json['collection_id']),
      videoId: _integer(json['video_id']),
      durationSeconds: _integer(json['duration']),
      title: _string(json['title']),
      description: _string(json['describe']),
      htmlContent: rawContent is String ? rawContent : '',
      imageContent: rawContent is List ? _stringList(rawContent) : const [],
      coverUrls: _stringList(json['cover_images']),
      horizontalCoverUrls: _stringList(json['horizontal_images']),
      secondaryCategoryName: _string(
        _map(json['plate_two_obj'])['name'] ?? json['plate_two_name'],
      ),
      price: price,
      salesCount: _integer(json['sales_num']),
      viewCount: _integer(json['views_num']),
      collectCount: _integer(json['collect_num']),
      likeCount: _integer(json['like_num']),
      coinCount: _integer(json['coin_num']),
      downloadPrice: _integer(json['download_price']),
      hasDownloadAccess: _integer(json['is_buy_download']) == 1,
      isPurchased: unlockType == 0 && price > 0,
      unlockType: unlockType,
      jumpRegister: _integer(json['jump_register']),
      isCollected: _integer(json['is_collect']) == 1,
      isLiked: _integer(json['is_like']) == 1,
      hasTippedCoin: _integer(json['is_tip_coin']) == 1,
      shareUrl: _string(json['share_url']),
      createdAt: DateTime.tryParse(_string(json['created_at'])),
      author: PostAuthor.fromJson(_map(json['member_obj'])),
      labels: _list(json['labelObj'], PostLabel.fromJson),
      videoChannels: _list(json['play_video_url'], PostVideoChannel.fromJson),
      advertisements: _list(json['advertise_obj'], PostAdvertisement.fromJson),
    );
  }

  final int id;
  final int memberId;
  final int primaryCategoryId;
  final int type;
  final int collectionType;
  final String collectionId;
  final int videoId;
  final int durationSeconds;
  final String title;
  final String description;
  final String htmlContent;
  final List<String> imageContent;
  final List<String> coverUrls;
  final List<String> horizontalCoverUrls;
  final String secondaryCategoryName;
  final double price;
  final int salesCount;
  final int viewCount;
  final int collectCount;
  final int likeCount;
  final int coinCount;
  final int downloadPrice;
  final bool hasDownloadAccess;
  final bool isPurchased;
  final int unlockType;
  final int jumpRegister;
  final bool isCollected;
  final bool isLiked;
  final bool hasTippedCoin;
  final String shareUrl;
  final DateTime? createdAt;
  final PostAuthor author;
  final List<PostLabel> labels;
  final List<PostVideoChannel> videoChannels;
  final List<PostAdvertisement> advertisements;

  String get coverUrl => coverUrls.isEmpty ? '' : coverUrls.first;
  bool get hasVideo => videoChannels.any((item) => item.url.isNotEmpty);
  bool get requiresCoinUnlock => unlockType == 1 && !isPurchased;
  bool get requiresVipUnlock => unlockType == 2;
  bool get requiresRegistration => jumpRegister == 1;
  bool get isCollection => collectionType == 1 || collectionId.isNotEmpty;
  bool get canDownload => videoId > 0;

  PostDetail copyWith({
    int? collectCount,
    int? likeCount,
    int? coinCount,
    bool? isPurchased,
    bool? isCollected,
    bool? isLiked,
    bool? hasTippedCoin,
    bool? hasDownloadAccess,
    PostAuthor? author,
  }) {
    return PostDetail(
      id: id,
      memberId: memberId,
      primaryCategoryId: primaryCategoryId,
      type: type,
      collectionType: collectionType,
      collectionId: collectionId,
      videoId: videoId,
      durationSeconds: durationSeconds,
      title: title,
      description: description,
      htmlContent: htmlContent,
      imageContent: imageContent,
      coverUrls: coverUrls,
      horizontalCoverUrls: horizontalCoverUrls,
      secondaryCategoryName: secondaryCategoryName,
      price: price,
      salesCount: salesCount,
      viewCount: viewCount,
      collectCount: collectCount ?? this.collectCount,
      likeCount: likeCount ?? this.likeCount,
      coinCount: coinCount ?? this.coinCount,
      downloadPrice: downloadPrice,
      hasDownloadAccess: hasDownloadAccess ?? this.hasDownloadAccess,
      isPurchased: isPurchased ?? this.isPurchased,
      unlockType: unlockType,
      jumpRegister: jumpRegister,
      isCollected: isCollected ?? this.isCollected,
      isLiked: isLiked ?? this.isLiked,
      hasTippedCoin: hasTippedCoin ?? this.hasTippedCoin,
      shareUrl: shareUrl,
      createdAt: createdAt,
      author: author ?? this.author,
      labels: labels,
      videoChannels: videoChannels,
      advertisements: advertisements,
    );
  }

  static String _string(Object? value) => value?.toString() ?? '';

  static int _integer(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _number(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static Map<String, dynamic> _map(Object? value) {
    return value is Map ? Map<String, dynamic>.from(value) : const {};
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return value
        .map(_string)
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);
  }

  static List<T> _list<T>(
    Object? value,
    T Function(Map<String, dynamic>) parser,
  ) {
    if (value is! List) return <T>[];
    return value
        .whereType<Map>()
        .map((item) => parser(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }
}

final class PostAuthor {
  const PostAuthor({
    required this.id,
    required this.nickname,
    required this.avatarUrl,
    required this.signature,
    required this.fanCount,
    required this.workCount,
    required this.isFollowing,
  });

  factory PostAuthor.fromJson(Map<String, dynamic> json) {
    return PostAuthor(
      id: PostDetail._integer(json['id']),
      nickname: PostDetail._string(json['nickname']),
      avatarUrl: PostDetail._string(json['head_sculpture']),
      signature: PostDetail._string(json['sign']),
      fanCount: PostDetail._integer(json['fan_num']),
      workCount: PostDetail._integer(json['work_num']),
      isFollowing: PostDetail._integer(
            json['is_fans'] ?? json['is_force'] ?? json['isForce'],
          ) ==
          1,
    );
  }

  final int id;
  final String nickname;
  final String avatarUrl;
  final String signature;
  final int fanCount;
  final int workCount;
  final bool isFollowing;

  PostAuthor copyWith({bool? isFollowing}) {
    return PostAuthor(
      id: id,
      nickname: nickname,
      avatarUrl: avatarUrl,
      signature: signature,
      fanCount: fanCount,
      workCount: workCount,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}

final class PostLabel {
  const PostLabel({required this.id, required this.name});

  factory PostLabel.fromJson(Map<String, dynamic> json) {
    return PostLabel(
      id: PostDetail._integer(json['id']),
      name: PostDetail._string(json['name']),
    );
  }

  final int id;
  final String name;
}

final class PostVideoChannel {
  const PostVideoChannel({required this.title, required this.url});

  factory PostVideoChannel.fromJson(Map<String, dynamic> json) {
    return PostVideoChannel(
      title: PostDetail._string(json['title']),
      url: PostDetail._string(json['url']),
    );
  }

  final String title;
  final String url;
}

final class PostAdvertisement {
  const PostAdvertisement({
    required this.id,
    required this.imageUrl,
    required this.targetUrl,
  });

  factory PostAdvertisement.fromJson(Map<String, dynamic> json) {
    return PostAdvertisement(
      id: PostDetail._integer(json['id']),
      imageUrl: PostDetail._string(json['advertise_image']),
      targetUrl: PostDetail._string(json['jump_url']),
    );
  }

  final int id;
  final String imageUrl;
  final String targetUrl;
}

final class PostRewardProduct {
  const PostRewardProduct({required this.id, required this.coinCount});

  factory PostRewardProduct.fromJson(Map<String, dynamic> json) {
    return PostRewardProduct(
      id: PostDetail._integer(json['id']),
      coinCount: PostDetail._integer(json['gold_num']),
    );
  }

  final int id;
  final int coinCount;
}

final class PostFeedbackReason {
  const PostFeedbackReason({required this.id, required this.content});

  factory PostFeedbackReason.fromJson(Map<String, dynamic> json) {
    return PostFeedbackReason(
      id: PostDetail._integer(json['id']),
      content: PostDetail._string(json['content']),
    );
  }

  final int id;
  final String content;
}
