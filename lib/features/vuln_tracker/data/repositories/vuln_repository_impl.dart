import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/vulnerability.dart';
import '../../domain/repositories/vuln_repository.dart';
import '../datasources/vuln_local_datasource.dart';
import '../datasources/vuln_remote_datasource.dart';

class VulnRepositoryImpl implements VulnRepository {
  VulnRepositoryImpl(this._local, this._remote);

  final VulnLocalDataSource _local;
  final VulnRemoteDataSource _remote;

  bool get _isLoggedIn => FirebaseAuth.instance.currentUser != null;

  // ──────────────────────────────────────────────
  // Watching: merge local + remote streams
  // ──────────────────────────────────────────────

  @override
  Stream<List<Vulnerability>> watchAll() {
    // Always stream local data first for instant UI response (offline-first)
    final localStream = _local.watchAll();

    if (_isLoggedIn) {
      // When logged in, also listen to Firestore. When a remote change arrives,
      // save it locally so the local stream reflects it too.
      _remote.watchAll().listen((remoteList) async {
        for (final vuln in remoteList) {
          await _local.save(vuln);
        }
      });
    }

    return localStream;
  }

  // ──────────────────────────────────────────────
  // CRUD operations: local first, then Firestore
  // ──────────────────────────────────────────────

  @override
  Future<List<Vulnerability>> getAll() => _local.getAll();

  @override
  Future<Vulnerability?> getById(String id) => _local.getById(id);

  @override
  Future<Vulnerability> create(Vulnerability vulnerability) async {
    // 1. Save locally first — instant, always works offline
    await _local.save(vulnerability);

    // 2. Push to Firestore in background if online & logged in
    _syncToRemote(vulnerability);

    return vulnerability;
  }

  @override
  Future<Vulnerability> update(Vulnerability vulnerability) async {
    await _local.save(vulnerability);
    _syncToRemote(vulnerability);
    return vulnerability;
  }

  @override
  Future<void> delete(String id) async {
    await _local.delete(id);
    if (_isLoggedIn) {
      _checkConnectivity().then((online) {
        if (online) _remote.delete(id);
      });
    }
  }

  @override
  Future<Vulnerability> addComment(String vulnId, VulnComment comment) async {
    final existing = await _local.getById(vulnId);
    if (existing == null) {
      throw StateError('Vulnerability not found: $vulnId');
    }
    final updated = existing.copyWith(
      comments: [...existing.comments, comment],
      updatedAt: DateTime.now(),
    );
    await _local.save(updated);
    _syncToRemote(updated);
    return updated;
  }

  @override
  Future<void> seedIfEmpty() => _local.seedIfEmpty();

  // ──────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────

  /// Fire-and-forget sync to Firestore (only if online & authenticated)
  void _syncToRemote(Vulnerability vuln) {
    if (!_isLoggedIn) return;
    _checkConnectivity().then((online) {
      if (online) _remote.save(vuln);
    });
  }

  Future<bool> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    return result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.ethernet);
  }
}

