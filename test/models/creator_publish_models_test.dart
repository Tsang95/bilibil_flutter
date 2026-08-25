import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/common/creator_access_policy.dart';
import 'package:b_flutter/models/creator_publish_models.dart';

void main() {
  test('creator publish options preserve legacy nested form data', () {
    final options = CreatorPublishOptions.fromJson(<String, dynamic>{
      'form_is_show': '1',
      'plateType': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': '3',
          'name': '影视',
          'son_type': <Map<String, dynamic>>[
            <String, dynamic>{'id': '9', 'name': '电影'},
          ],
        },
      ],
      'collectionType': <Map<String, dynamic>>[
        <String, dynamic>{'id': 2, 'name': '加入合集'},
      ],
      'postContentTypes': <Map<String, dynamic>>[
        <String, dynamic>{'id': 1, 'name': '视频'},
      ],
      'sale_price_collection': <Map<String, dynamic>>[
        <String, dynamic>{'value': '8', 'label': '8金币'},
      ],
    });

    expect(options.formIsShown, isTrue);
    expect(options.plates.single.id, 3);
    expect(options.plates.single.categories.single.name, '电影');
    expect(options.collectionTypes.single.id, 2);
    expect(options.contentTypes.single.name, '视频');
    expect(options.prices.single.value, 8);
  });

  test('UP membership publishing gate is restored after QA', () {
    expect(CreatorAccessPolicy.allowPublishingWithoutVip, isFalse);
  });
}
