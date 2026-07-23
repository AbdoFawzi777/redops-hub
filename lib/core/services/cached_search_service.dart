import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class CachedSearchService {
  static final CachedSearchService _instance = CachedSearchService._internal();
  factory CachedSearchService() => _instance;
  CachedSearchService._internal();

  Box? _cacheBox;
  static const Duration _cacheDuration = Duration(hours: 24);
  static const int _maxCacheSize = 100;

  Future<void> init() async {
    try {
      if (!Hive.isBoxOpen('search_cache')) {
        _cacheBox = await Hive.openBox('search_cache');
      } else {
        _cacheBox = Hive.box('search_cache');
      }
    } catch (e) {
      debugPrint('CachedSearchService init error: $e');
    }
  }

  /// Perform search with caching
  Future<List<Map<String, dynamic>>> search({
    required String query,
    required Future<List<Map<String, dynamic>>> Function(String) searchFunction,
  }) async {
    // 1. Check cache
    final cached = await _getCached(query);
    if (cached != null) {
      debugPrint('📦 Using cached search results for: $query');
      return cached;
    }

    // 2. Perform live search
    debugPrint('🔍 Performing live query for: $query');
    final results = await searchFunction(query);

    // 3. Store result in cache
    if (results.isNotEmpty) {
      await _storeCache(query, results);
    }

    return results;
  }

  /// Retrieve cached result
  Future<List<Map<String, dynamic>>?> _getCached(String query) async {
    if (_cacheBox == null) return null;
    try {
      final key = _generateCacheKey(query);
      final cached = _cacheBox!.get(key);

      if (cached == null) return null;

      final timestamp = DateTime.parse(cached['timestamp']);
      final age = DateTime.now().difference(timestamp);

      if (age > _cacheDuration) {
        await _cacheBox!.delete(key);
        return null;
      }

      return List<Map<String, dynamic>>.from(cached['data']);
    } catch (e) {
      debugPrint('Error retrieving search cache: $e');
      return null;
    }
  }

  /// Store result in cache
  Future<void> _storeCache(String query, List<Map<String, dynamic>> results) async {
    if (_cacheBox == null) return;
    try {
      if (_cacheBox!.length >= _maxCacheSize) {
        await _removeOldestEntry();
      }

      final key = _generateCacheKey(query);
      await _cacheBox!.put(key, {
        'data': results,
        'timestamp': DateTime.now().toIso8601String(),
        'query': query,
        'count': results.length,
      });

      debugPrint('💾 Cached ${results.length} results for: $query');
    } catch (e) {
      debugPrint('⚠️ Cache storage failed: $e');
    }
  }

  /// Fast offline search in cache (sub-100ms)
  Future<List<Map<String, dynamic>>> searchOffline(String query) async {
    if (_cacheBox == null) return [];
    try {
      final key = _generateCacheKey(query);
      final cached = _cacheBox!.get(key);

      if (cached != null) {
        return List<Map<String, dynamic>>.from(cached['data']);
      }

      return _partialSearchOffline(query);
    } catch (e) {
      return [];
    }
  }

  /// Partial search across all cached queries
  List<Map<String, dynamic>> _partialSearchOffline(String query) {
    if (_cacheBox == null) return [];
    final results = <Map<String, dynamic>>[];
    final queryLower = query.toLowerCase().trim();

    for (final key in _cacheBox!.keys) {
      if (key.toString().startsWith('search_')) {
        final cached = _cacheBox!.get(key);
        if (cached != null) {
          final data = List<Map<String, dynamic>>.from(cached['data']);
          final matches = data.where((item) {
            final name = (item['name'] ?? item['title'] ?? item['cve_id'] ?? '').toString().toLowerCase();
            final desc = (item['description'] ?? item['summary'] ?? '').toString().toLowerCase();
            return name.contains(queryLower) || desc.contains(queryLower);
          }).toList();

          results.addAll(matches);
        }
      }
    }

    return results;
  }

  /// Remove oldest cache entry if max capacity reached
  Future<void> _removeOldestEntry() async {
    if (_cacheBox == null) return;
    try {
      String? oldestKey;
      DateTime? oldestTime;

      for (final key in _cacheBox!.keys) {
        if (key.toString().startsWith('search_')) {
          final cached = _cacheBox!.get(key);
          if (cached != null) {
            final timestamp = DateTime.parse(cached['timestamp']);
            if (oldestTime == null || timestamp.isBefore(oldestTime)) {
              oldestTime = timestamp;
              oldestKey = key.toString();
            }
          }
        }
      }

      if (oldestKey != null) {
        await _cacheBox!.delete(oldestKey);
        debugPrint('🗑️ Evicted oldest search cache entry');
      }
    } catch (e) {
      debugPrint('⚠️ Error evicting oldest cache entry: $e');
    }
  }

  String _generateCacheKey(String query) {
    return 'search_${query.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '_')}';
  }

  Future<void> clearCache() async {
    if (_cacheBox == null) return;
    await _cacheBox!.clear();
    debugPrint('🧹 Search cache cleared completely');
  }

  Map<String, dynamic> getCacheStats() {
    if (_cacheBox == null) return {'totalEntries': 0, 'totalResults': 0, 'maxEntries': _maxCacheSize};
    int totalEntries = 0;
    int totalResults = 0;

    for (final key in _cacheBox!.keys) {
      if (key.toString().startsWith('search_')) {
        totalEntries++;
        final cached = _cacheBox!.get(key);
        if (cached != null) {
          totalResults += (cached['count'] as int? ?? 0);
        }
      }
    }

    return {
      'totalEntries': totalEntries,
      'totalResults': totalResults,
      'maxEntries': _maxCacheSize,
    };
  }
}
