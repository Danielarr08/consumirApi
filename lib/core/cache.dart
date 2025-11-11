class CacheEntry<T> {
  final T data;
  final DateTime ts;
  CacheEntry(this.data) : ts = DateTime.now();
}

class MemoryCache<T> {
  final Duration ttl;
  CacheEntry<T>? _entry;
  MemoryCache({this.ttl = const Duration(minutes: 5)});

  T? get() {
    final e = _entry;
    if (e == null) return null;
    if (DateTime.now().difference(e.ts) > ttl) return null;
    return e.data;
  }

  void set(T data) => _entry = CacheEntry<T>(data);
  void clear() => _entry = null;
}
