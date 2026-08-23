import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:b_flutter/stores/search_history_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('search history is unique, newest first and can be cleared', () async {
    final store = SearchHistoryStore.instance;
    await store.add('电影');
    await store.add('动漫');
    final history = await store.add('电影');

    expect(history, <String>['电影', '动漫']);

    await store.clear();
    expect(await store.getHistory(), isEmpty);
  });

  test('search history retains at most twenty entries', () async {
    final store = SearchHistoryStore.instance;
    for (var index = 0; index < 25; index++) {
      await store.add('关键词$index');
    }

    final history = await store.getHistory();
    expect(history, hasLength(20));
    expect(history.first, '关键词24');
    expect(history.last, '关键词5');
  });
}
