import 'package:shared_preferences/shared_preferences.dart';

final class SearchHistoryStore {
  SearchHistoryStore._();

  static final SearchHistoryStore instance = SearchHistoryStore._();
  static const String _storageKey = 'search_history_v2';
  static const int _maximumItems = 20;

  Future<List<String>> getHistory() async {
    final preferences = await SharedPreferences.getInstance();
    return List<String>.unmodifiable(
      preferences
              .getStringList(_storageKey)
              ?.map((item) => item.trim())
              .where((item) => item.isNotEmpty) ??
          const <String>[],
    );
  }

  Future<List<String>> add(String keyword) async {
    final normalized = keyword.trim();
    if (normalized.isEmpty) return getHistory();

    final history = (await getHistory()).toList()
      ..removeWhere((item) => item == normalized)
      ..insert(0, normalized);
    if (history.length > _maximumItems) {
      history.removeRange(_maximumItems, history.length);
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_storageKey, history);
    return List<String>.unmodifiable(history);
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
  }
}
