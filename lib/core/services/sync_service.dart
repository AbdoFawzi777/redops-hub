import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class SyncStatus {
  final int pendingItems;
  final bool isConnected;
  final bool isSyncing;

  SyncStatus({
    required this.pendingItems,
    required this.isConnected,
    required this.isSyncing,
  });

  bool get hasPending => pendingItems > 0;
  bool get isReady => isConnected && hasPending && !isSyncing;
}

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  Box? _syncQueueBox;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  /// Initialize service
  Future<void> init() async {
    try {
      if (!Hive.isBoxOpen('sync_queue')) {
        _syncQueueBox = await Hive.openBox('sync_queue');
      } else {
        _syncQueueBox = Hive.box('sync_queue');
      }
    } catch (e) {
      debugPrint('SyncService init error: $e');
    }
  }

  /// Enqueue item for background sync
  Future<void> addToSyncQueue({
    required String collection,
    required String id,
    required Map<String, dynamic> data,
    String operation = 'set',
  }) async {
    final queueItem = {
      'collection': collection,
      'id': id,
      'data': data,
      'operation': operation,
      'timestamp': DateTime.now().toIso8601String(),
      'retries': 0,
    };

    final key = '${collection}_$id';
    if (_syncQueueBox != null) {
      await _syncQueueBox!.put(key, queueItem);
      debugPrint('📦 Enqueued item for sync: $collection/$id');
    }

    if (await _isConnected()) {
      await processSyncQueue();
    }
  }

  /// Process queue
  Future<void> processSyncQueue() async {
    if (_syncQueueBox == null) return;
    if (!await _isConnected()) {
      debugPrint('⚠️ Network unavailable, postponing sync queue processing.');
      return;
    }

    final keys = _syncQueueBox!.keys.toList();
    if (keys.isEmpty) return;
    debugPrint('🔄 Processing ${keys.length} item(s) in sync queue...');

    for (final key in keys) {
      try {
        final item = Map<String, dynamic>.from(_syncQueueBox!.get(key));
        await _syncItem(item);
        await _syncQueueBox!.delete(key);
        debugPrint('✅ Synced successfully: ${item['collection']}/${item['id']}');
      } catch (e) {
        final itemRaw = _syncQueueBox!.get(key);
        if (itemRaw != null) {
          final item = Map<String, dynamic>.from(itemRaw);
          item['retries'] = (item['retries'] as int? ?? 0) + 1;

          if (item['retries'] >= 5) {
            await _syncQueueBox!.delete(key);
            debugPrint('❌ Dropped queue item after 5 failed attempts: ${item['collection']}/${item['id']}');
          } else {
            await _syncQueueBox!.put(key, item);
            debugPrint('⚠️ Sync attempt failed for ${item['collection']}/${item['id']} (Retry #${item['retries']})');
          }
        }
      }
    }
  }

  Future<void> _syncItem(Map<String, dynamic> item) async {
    final docRef = _firestore.collection(item['collection']).doc(item['id']);

    switch (item['operation']) {
      case 'set':
        await docRef.set(item['data'], SetOptions(merge: true));
        break;
      case 'delete':
        await docRef.delete();
        break;
      case 'update':
        await docRef.update(item['data']);
        break;
    }
  }

  Future<bool> _isConnected() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return !connectivityResult.contains(ConnectivityResult.none);
    } catch (_) {
      return true;
    }
  }

  Future<SyncStatus> getSyncStatus() async {
    final pending = _syncQueueBox?.length ?? 0;
    final isConnected = await _isConnected();

    return SyncStatus(
      pendingItems: pending,
      isConnected: isConnected,
      isSyncing: false,
    );
  }

  Future<void> retrySync() async {
    await processSyncQueue();
  }
}
