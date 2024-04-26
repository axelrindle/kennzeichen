import 'dart:core';
import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:kennzeichen/main.dart';

class CacheEntry<V> {
  final V? _cacheObject;
  final DateTime _createTime;

  CacheEntry(this._cacheObject, this._createTime);

  DateTime get createTime => _createTime;

  get cacheObject => _cacheObject;
}

class InflightEntry<V> {
  final Completer<V> _completer;
  final DateTime _createTime;

  InflightEntry(this._completer, this._createTime);

  DateTime get createTime => _createTime;

  Completer<V> get completer => _completer;
}

/// A FIFO cache. Its entries will expire after a given time period.
///
/// The cache entry will get remove when it is the first inserted entry and
/// cache reach its limited size, or when it is expired.
///
/// You can use markAsInFlight to indicate that there will be a set call after.
/// Then before this key's corresponding value is set, all the other get to this
/// key will wait on the same [Future].
class ExpireCache<K, V> {
  /// The duration between entry create and expire. Default 120 seconds
  final Duration expireDuration;

  /// The duration between each garbage collection. Default 180 seconds.
  final Duration gcDuration;

  /// The upper size limit of [_cache](the cache's max entry number).
  final int sizeLimit;

  /// The internal cache that stores the cache entries.
  var _cache = <K, CacheEntry<V>>{};

  get cache => _cache;

  /// Map of outstanding set used to prevent concurrent loads of the same key.
  final _inflightSet = <K, InflightEntry<V>>{};

  ExpireCache({
    this.sizeLimit = 100,
    this.expireDuration = const Duration(seconds: 120),
    this.gcDuration = const Duration(seconds: 180)
  }) : assert(sizeLimit > 0);

  Future<void> load() async {
    final loaded = MyApp.get().prefs.get('geoCache');
    if (loaded is Map<K, CacheEntry<V>>) {
      _cache = loaded;
    }
  }

  Future<void> save() async {
    final dir = await getApplicationCacheDirectory();
    final file = File("${dir.path}/geoCache.dat");

    // await file.writeAsBytes(bytes);
  }
  
  /// Sets the value associated with [key]. The Future completes with null when
  /// the operation is complete.
  ///
  /// Setting the same key should make that key the latest key in [_cache].
  Future<Null> set(K key, V value) async {
    if (_inflightSet.containsKey(key)) {
      _inflightSet[key]!._completer.complete(value);
      _inflightSet.remove(key);
    }
    // Removing the key and adding it again will make it be last in the
    // iteration order.
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    }
    _cache[key] = CacheEntry(value, DateTime.now());
    if (_cache.length > sizeLimit) {
      removeFirst();
    }
  }

  /// Expire all the outdated cache and inflight entries.
  ///
  /// [_cache] and [_inflightSet] are [LinkedHashMap], which is iterated by time
  /// order. So we just need to stop when we sees the first not expired value.
  Future<Null> expireOutdatedEntries() async {
    _cache.keys
        .takeWhile((value) => isCacheEntryExpired(value))
        .toList()
        .forEach(_cache.remove);
    _inflightSet.keys
        .takeWhile((value) => isInflightEntryExpire(value))
        .toList()
        .forEach(_inflightSet.remove);
  }

  /// The number of entry in the cache.
  int length() => _cache.length;

  /// Returns true if there is no entry in the cache. Doesn't matter if there is
  /// any inflight entry.
  bool isEmpty() => _cache.isEmpty;

  /// The number of entry in the inflight set.
  int inflightLength() => _inflightSet.length;

  void removeFirst() {
    _cache.remove(_cache.keys.first);
  }

  /// Removes the value associated with [key]. The Future completes with null
  /// when the operation is complete.
  Future<Null> invalidate(K key) async {
    _cache.remove(key);
    _inflightSet.remove(key);
  }

  bool isCacheEntryExpired(K key) =>
      DateTime.now().difference(_cache[key]!._createTime) > expireDuration;

  bool isInflightEntryExpire(K key) =>
      DateTime.now().difference(_inflightSet[key]!._createTime) > expireDuration;

  /// Returns the value associated with [key].
  ///
  /// If the [key] is inflight, it will get the [Future] of that inflight key.
  /// Will invalidate the entry if it is expired.
  Future<V?> get(K key) async {
    if (_cache.containsKey(key) && isCacheEntryExpired(key)) {
      _cache.remove(key);
      return null;
    }
    if (_inflightSet.containsKey(key) && isInflightEntryExpire(key)) {
      _inflightSet.remove(key);
      return null;
    }

    final obj = _cache[key]?._cacheObject;
    return obj != null ? Future.value(obj) : _inflightSet[key]?._completer.future;
  }

  /// Mark a key as inflight. Calling this again or on a already cached entry
  /// will have no effect.
  ///
  /// All the get function call on the same key after this will get the same
  /// result.
  Future<Null> markAsInFlight(K key) async {
    if (!isKeyInFlightOrInCache(key)) {
      _inflightSet[key] = InflightEntry(Completer(), DateTime.now());
    }
  }

  void clear() {
    _cache.clear();
    _inflightSet.clear();
  }

  bool containsKey(K key) => _cache.containsKey(key);

  bool isKeyInFlightOrInCache(K key) =>
      _inflightSet.containsKey(key) || _cache.containsKey(key);

  get inflightSet => _inflightSet;
}
