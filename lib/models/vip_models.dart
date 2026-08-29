final class VipProduct {
  const VipProduct({
    required this.id,
    required this.name,
    required this.days,
    required this.price,
    required this.oldPrice,
    required this.commentLimit,
    required this.privateMessageLimit,
    required this.postLimit,
    required this.categoryNames,
  });

  factory VipProduct.fromJson(Map<String, dynamic> json) => VipProduct(
        id: _integer(json['id']),
        name: json['name']?.toString() ?? '',
        days: _integer(json['real_day']),
        price: _number(json['price']),
        oldPrice: _number(json['old_price']),
        commentLimit: _integer(json['comment_num']),
        privateMessageLimit: _integer(json['private_letter_num']),
        postLimit: _integer(json['post_num']),
        categoryNames: (json['circleObj'] ?? json['circle_obj']) is List
            ? ((json['circleObj'] ?? json['circle_obj']) as List)
                .whereType<Map>()
                .map((item) => item['name']?.toString() ?? '')
                .where((name) => name.isNotEmpty)
                .toList(growable: false)
            : const <String>[],
      );

  final int id;
  final String name;
  final int days;
  final double price;
  final double oldPrice;
  final int commentLimit;
  final int privateMessageLimit;
  final int postLimit;
  final List<String> categoryNames;

  static int _integer(Object? value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
  static double _number(Object? value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;
}

final class WalletChangeRecord {
  const WalletChangeRecord({
    required this.id,
    required this.title,
    required this.content,
    required this.amount,
    required this.createdAt,
  });

  factory WalletChangeRecord.fromJson(Map<String, dynamic> json) =>
      WalletChangeRecord(
        id: VipProduct._integer(json['id']),
        title: json['title']?.toString() ?? '',
        content: json['content']?.toString() ?? '',
        amount: VipProduct._number(json['gold_num']),
        createdAt: json['created_at']?.toString() ?? '',
      );

  final int id;
  final String title;
  final String content;
  final double amount;
  final String createdAt;
}

final class RechargeProduct {
  const RechargeProduct({
    required this.id,
    required this.goldCoin,
    required this.price,
    required this.oldPrice,
    required this.isSelected,
    required this.additional,
  });

  factory RechargeProduct.fromJson(Map<String, dynamic> json) =>
      RechargeProduct(
        id: VipProduct._integer(json['id']),
        goldCoin: VipProduct._integer(json['gold_coin']),
        price: VipProduct._number(json['price']),
        oldPrice: VipProduct._number(json['old_price']),
        isSelected: VipProduct._integer(json['is_selected']) == 1,
        additional: json['additional']?.toString() ?? '',
      );

  final int id;
  final int goldCoin;
  final double price;
  final double oldPrice;
  final bool isSelected;
  final String additional;
}

final class RechargeChannel {
  const RechargeChannel({
    required this.id,
    required this.type,
    required this.name,
  });

  factory RechargeChannel.fromJson(Map<String, dynamic> json) =>
      RechargeChannel(
        id: VipProduct._integer(json['id']),
        type: VipProduct._integer(json['type']),
        name: json['desc']?.toString() ?? '',
      );

  final int id;
  final int type;
  final String name;
}

final class RechargeOrder {
  const RechargeOrder({
    required this.url,
    required this.amount,
    required this.coin,
    required this.address,
    required this.usdtPrice,
  });

  factory RechargeOrder.fromJson(Map<String, dynamic> json) => RechargeOrder(
        url: json['pay_url']?.toString() ?? '',
        amount: VipProduct._number(json['amount']),
        coin: json['coin']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        usdtPrice: VipProduct._number(json['usdt_price']),
      );

  final String url;
  final double amount;
  final String coin;
  final String address;
  final double usdtPrice;

  bool get isUsdt => address.trim().isNotEmpty;
}

final class RechargeHistoryRecord {
  const RechargeHistoryRecord({
    required this.id,
    required this.amount,
    required this.createdAt,
    required this.isPaid,
  });

  factory RechargeHistoryRecord.fromJson(Map<String, dynamic> json) =>
      RechargeHistoryRecord(
        id: VipProduct._integer(json['id']),
        amount: VipProduct._number(json['money']),
        createdAt: json['created_at']?.toString() ?? '',
        isPaid: VipProduct._integer(json['pay_status']) == 1,
      );

  final int id;
  final double amount;
  final String createdAt;
  final bool isPaid;
}

enum WithdrawLinkType {
  erc20,
  trc20;

  int get value => index;
  String get label => this == WithdrawLinkType.erc20 ? 'ERC20' : 'TRC20';
}

enum WithdrawStatus {
  processing,
  success,
  failed;

  factory WithdrawStatus.fromValue(Object? value) {
    final status = VipProduct._integer(value);
    return status == 1
        ? WithdrawStatus.success
        : status == -1
            ? WithdrawStatus.failed
            : WithdrawStatus.processing;
  }

  String get label => switch (this) {
        WithdrawStatus.processing => '进行中...',
        WithdrawStatus.success => '提现成功',
        WithdrawStatus.failed => '提现失败',
      };
}

final class WithdrawRecord {
  const WithdrawRecord({
    required this.id,
    required this.linkType,
    required this.coinAddress,
    required this.qrCodeUrl,
    required this.goldAmount,
    required this.actualAmount,
    required this.exchangeRate,
    required this.actualCoin,
    required this.status,
    required this.notes,
    required this.updatedAt,
  });

  factory WithdrawRecord.fromJson(Map<String, dynamic> json) => WithdrawRecord(
        id: VipProduct._integer(json['id']),
        linkType: VipProduct._integer(json['link_type']) == 1
            ? WithdrawLinkType.trc20
            : WithdrawLinkType.erc20,
        coinAddress: json['coin_address']?.toString() ?? '',
        qrCodeUrl: json['address_qr_code']?.toString() ?? '',
        goldAmount: VipProduct._integer(json['gold_num']),
        actualAmount: VipProduct._number(json['real_num']),
        exchangeRate: VipProduct._number(json['exchange_rate']),
        actualCoin: VipProduct._number(json['real_coin']),
        status: WithdrawStatus.fromValue(json['status']),
        notes: json['notes']?.toString() ?? '',
        updatedAt: json['updated_at']?.toString() ??
            json['created_at']?.toString() ??
            '',
      );

  final int id;
  final WithdrawLinkType linkType;
  final String coinAddress;
  final String qrCodeUrl;
  final int goldAmount;
  final double actualAmount;
  final double exchangeRate;
  final double actualCoin;
  final WithdrawStatus status;
  final String notes;
  final String updatedAt;
}
