typedef Clock = DateTime Function();

enum CacheMode { disabled, cacheFirst, networkFirst }

final class CachePolicy {
  const CachePolicy._({
    required this.mode,
    required this.ttl,
    required this.allowStaleOnError,
  });

  const CachePolicy.disabled()
    : this._(
        mode: CacheMode.disabled,
        ttl: Duration.zero,
        allowStaleOnError: false,
      );

  const CachePolicy.cacheFirst({
    Duration ttl = const Duration(minutes: 10),
    bool allowStaleOnError = true,
  }) : this._(
         mode: CacheMode.cacheFirst,
         ttl: ttl,
         allowStaleOnError: allowStaleOnError,
       );

  const CachePolicy.networkFirst({
    Duration ttl = const Duration(minutes: 10),
    bool allowStaleOnError = true,
  }) : this._(
         mode: CacheMode.networkFirst,
         ttl: ttl,
         allowStaleOnError: allowStaleOnError,
       );

  final CacheMode mode;
  final Duration ttl;
  final bool allowStaleOnError;

  bool get enabled => mode != CacheMode.disabled;
}

final class CacheLookup {
  const CacheLookup({required this.value, required this.isStale});

  final Object? value;
  final bool isStale;
}

final class RequestCache {
  RequestCache({Clock? clock}) : _clock = clock ?? DateTime.now;

  static final RequestCache instance = RequestCache();

  final Clock _clock;
  final Map<String, _CacheEntry> _entries = <String, _CacheEntry>{};

  int get length => _entries.length;

  CacheLookup? lookup(String key, {bool includeStale = false}) {
    final entry = _entries[key];
    if (entry == null) return null;

    final isStale = !_clock().isBefore(entry.expiresAt);
    if (isStale && !includeStale) return null;
    return CacheLookup(value: entry.value, isStale: isStale);
  }

  void put(
    String key,
    Object? value, {
    required Duration ttl,
    Set<String> tags = const <String>{},
  }) {
    if (ttl <= Duration.zero) return;
    _entries[key] = _CacheEntry(
      value: value,
      expiresAt: _clock().add(ttl),
      tags: Set<String>.unmodifiable(tags),
    );
  }

  void remove(String key) => _entries.remove(key);

  void invalidateTags(Iterable<String> tags) {
    final requestedTags = tags.toSet();
    if (requestedTags.isEmpty) return;
    _entries.removeWhere((_, entry) => entry.tags.any(requestedTags.contains));
  }

  void clearScope(String scope) {
    _entries.removeWhere((key, _) => key.startsWith('$scope|'));
  }

  void clear() => _entries.clear();

  void pruneExpired() {
    final now = _clock();
    _entries.removeWhere((_, entry) => !now.isBefore(entry.expiresAt));
  }
}

final class _CacheEntry {
  const _CacheEntry({
    required this.value,
    required this.expiresAt,
    required this.tags,
  });

  final Object? value;
  final DateTime expiresAt;
  final Set<String> tags;
}
