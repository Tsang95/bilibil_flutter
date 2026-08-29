final class CreatorPublishOption {
  const CreatorPublishOption({required this.id, required this.name});

  factory CreatorPublishOption.fromJson(Map<String, dynamic> json) =>
      CreatorPublishOption(
        id: _integer(json['id']),
        name: _string(json['name'] ?? json['title']),
      );

  final int id;
  final String name;
}

final class CreatorPlate {
  const CreatorPlate({
    required this.id,
    required this.name,
    required this.categories,
  });

  factory CreatorPlate.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['son_type'];
    return CreatorPlate(
      id: _integer(json['id']),
      name: _string(json['name']),
      categories: rawCategories is List
          ? rawCategories
              .whereType<Map>()
              .map(
                (item) => CreatorPublishOption.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(growable: false)
          : const <CreatorPublishOption>[],
    );
  }

  final int id;
  final String name;
  final List<CreatorPublishOption> categories;
}

final class CreatorPriceOption {
  const CreatorPriceOption({required this.value, required this.label});

  factory CreatorPriceOption.fromJson(Map<String, dynamic> json) =>
      CreatorPriceOption(
        value: _integer(json['value']),
        label: _string(json['label']),
      );

  final int value;
  final String label;
}

final class CreatorPublishOptions {
  const CreatorPublishOptions({
    required this.formIsShown,
    required this.plates,
    required this.collectionTypes,
    required this.contentTypes,
    required this.prices,
  });

  factory CreatorPublishOptions.fromJson(Map<String, dynamic> json) =>
      CreatorPublishOptions(
        formIsShown: _integer(json['form_is_show']) == 1,
        plates: _parseList(json['plateType'], CreatorPlate.fromJson),
        collectionTypes: _parseList(
          json['collectionType'],
          CreatorPublishOption.fromJson,
        ),
        contentTypes: _parseList(
          json['postContentTypes'],
          CreatorPublishOption.fromJson,
        ),
        prices: _parseList(
          json['sale_price_collection'],
          CreatorPriceOption.fromJson,
        ),
      );

  final bool formIsShown;
  final List<CreatorPlate> plates;
  final List<CreatorPublishOption> collectionTypes;
  final List<CreatorPublishOption> contentTypes;
  final List<CreatorPriceOption> prices;
}

List<T> _parseList<T>(Object? value, T Function(Map<String, dynamic>) parser) =>
    value is List
        ? value
            .whereType<Map>()
            .map((item) => parser(Map<String, dynamic>.from(item)))
            .toList(growable: false)
        : <T>[];

String _string(Object? value) => value?.toString() ?? '';

int _integer(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
