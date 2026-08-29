final class GameCategory {
  const GameCategory({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.games,
  });

  factory GameCategory.fromJson(Map<String, dynamic> json) {
    final children = json['child'];
    return GameCategory(
      id: _integer(json['id']),
      name: json['name']?.toString() ?? '',
      iconUrl: json['thumb']?.toString() ?? '',
      games: children is List
          ? children
              .whereType<Map>()
              .map(
                (item) => GameItem.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(growable: false)
          : const <GameItem>[],
    );
  }

  final int id;
  final String name;
  final String iconUrl;
  final List<GameItem> games;
}

final class GameItem {
  const GameItem({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
  });

  factory GameItem.fromJson(Map<String, dynamic> json) => GameItem(
        id: _integer(json['id']),
        name: json['name']?.toString() ?? '',
        thumbnailUrl: json['thumb']?.toString() ?? '',
      );

  final int id;
  final String name;
  final String thumbnailUrl;
}

final class GameActivity {
  const GameActivity({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.startTime,
    required this.endTime,
    required this.html,
  });

  factory GameActivity.fromJson(Map<String, dynamic> json) => GameActivity(
        id: _integer(json['id']),
        title: json['title']?.toString() ?? '',
        thumbnailUrl: json['thumb']?.toString() ?? '',
        startTime: _integer(json['start_time']),
        endTime: _integer(json['end_time']),
        html: json['content']?.toString() ?? '',
      );

  final int id;
  final String title;
  final String thumbnailUrl;
  final int startTime;
  final int endTime;
  final String html;
}

final class GameLaunch {
  const GameLaunch({
    required this.url,
    required this.showType,
    required this.platformId,
  });

  factory GameLaunch.fromJson(Map<String, dynamic> json) => GameLaunch(
        url: json['jump_url']?.toString() ?? '',
        showType: _integer(json['show_type']),
        platformId: _integer(json['platform_id']),
      );

  final String url;
  final int showType;
  final int platformId;

  bool get isLandscape => showType == 2;
}

final class GameRechargeRecord {
  const GameRechargeRecord({
    required this.id,
    required this.amountInCents,
    required this.status,
    required this.statusText,
    required this.createdAt,
  });
  factory GameRechargeRecord.fromJson(Map<String, dynamic> json) =>
      GameRechargeRecord(
        id: _integer(json['id']),
        amountInCents: _integer(json['amount']),
        status: _integer(json['status']),
        statusText: json['status_str']?.toString() ?? '',
        createdAt: _integer(json['created_at']),
      );
  final int id;
  final int amountInCents;
  final int status;
  final String statusText;
  final int createdAt;
}

/// Withdrawal prerequisites returned by the legacy `paymentDrawNeed` API.
final class GameWithdrawNeed {
  const GameWithdrawNeed({
    required this.amountInCents,
    required this.requiredAmountInCents,
    required this.bankBinding,
  });

  factory GameWithdrawNeed.fromJson(Map<String, dynamic> json) =>
      GameWithdrawNeed(
        amountInCents: _integer(json['amount']),
        requiredAmountInCents: _integer(json['need_amount']),
        bankBinding: json['bing'] is Map
            ? GameBankBinding.fromJson(
                Map<String, dynamic>.from(json['bing'] as Map),
              )
            : null,
      );

  final int amountInCents;
  final int requiredAmountInCents;
  final GameBankBinding? bankBinding;

  bool get isBankBound => bankBinding?.isBound == true;
}

final class GameBankBinding {
  const GameBankBinding({
    required this.isBound,
    required this.cardNumber,
    required this.bankName,
  });

  factory GameBankBinding.fromJson(Map<String, dynamic> json) =>
      GameBankBinding(
        isBound:
            _integer(json['is_bing']) == 1 || _integer(json['is_bind']) == 1,
        // `paymentDrawNeed.bing` names the two rendered values `bank` and
        // `card`, while `bankbind` returns them as `card_number` and
        // `bank_name` in the inverse order used by the old controller.
        // Preserve that display order for both response shapes.
        bankName: (json['bank'] ?? json['card_number'] ?? json['bank_name'])
                ?.toString() ??
            '',
        cardNumber: (json['card'] ?? json['bank_name'] ?? json['card_number'])
                ?.toString() ??
            '',
      );

  final bool isBound;
  final String cardNumber;
  final String bankName;
}

final class GameBank {
  const GameBank({required this.id, required this.name});

  factory GameBank.fromJson(Map<String, dynamic> json) =>
      GameBank(id: _integer(json['id']), name: json['name']?.toString() ?? '');

  final int id;
  final String name;
}

final class GameRechargeCategory {
  const GameRechargeCategory({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
  });

  factory GameRechargeCategory.fromJson(Map<String, dynamic> json) =>
      GameRechargeCategory(
        id: _integer(json['id']),
        name: json['name']?.toString() ?? '',
        thumbnailUrl: json['thumb']?.toString() ?? '',
      );

  final int id;
  final String name;
  final String thumbnailUrl;
}

final class GamePaymentChannel {
  const GamePaymentChannel({
    required this.id,
    required this.name,
    required this.quickAmounts,
  });

  factory GamePaymentChannel.fromJson(Map<String, dynamic> json) =>
      GamePaymentChannel(
        id: _integer(json['id']),
        name: json['name']?.toString() ?? '',
        quickAmounts: (json['quick_config'] as List? ?? const <Object?>[])
            .map((item) => item?.toString() ?? '')
            .where((item) => item.isNotEmpty)
            .toList(growable: false),
      );

  final int id;
  final String name;
  final List<String> quickAmounts;
}

int _integer(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
