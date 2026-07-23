import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import '../models/cve_model.dart';

class CveRemoteDataSource {
  final Dio _dio = Dio();

  static List<CveModel> _cachedCves = [];

  Future<List<CveModel>> getLatestCves() async {
    try {
      // 1. Primary: Shodan CVEDB API (Zero API key required, Includes CISA KEV & EPSS)
      final response = await _dio.get(
        'https://cvedb.shodan.io/cves',
        queryParameters: {'is_kev': 'true'},
        options: Options(receiveTimeout: const Duration(seconds: 8)),
      );

      if (response.statusCode == 200 && response.data != null) {
        final List cvesList = response.data['cves'] ?? response.data ?? [];
        if (cvesList.isNotEmpty) {
          _cachedCves = cvesList.take(20).map((v) => CveModel.fromJson(Map<String, dynamic>.from(v))).toList();
          return _cachedCves;
        }
      }
    } catch (e) {
      developer.log('Shodan CVEDB failed, switching to NIST NVD API.', name: 'CVE-Intel', error: e);
    }

    try {
      // 2. Secondary: NIST NVD API v2
      final response = await _dio.get(
        'https://services.nvd.nist.gov/rest/json/cves/2.0',
        queryParameters: {'resultsPerPage': 20, 'startIndex': 0},
        options: Options(receiveTimeout: const Duration(seconds: 8)),
      );

      if (response.statusCode == 200 && response.data != null) {
        final List vulnerabilities = response.data['vulnerabilities'] ?? [];
        if (vulnerabilities.isNotEmpty) {
          _cachedCves = vulnerabilities.take(20).map((v) => CveModel.fromJson(Map<String, dynamic>.from(v))).toList();
          return _cachedCves;
        }
      }
    } catch (nvdErr) {
      developer.log('NIST NVD failed, switching to CIRCL CVE Backup API.', name: 'CVE-Intel', error: nvdErr);
    }

    try {
      // 3. Fallback: CIRCL CVE Search API
      final response = await _dio.get(
        'https://cve.circl.lu/api/last',
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );

      if (response.statusCode == 200 && response.data is List) {
        final List vulnerabilities = response.data;
        if (vulnerabilities.isNotEmpty) {
          _cachedCves = vulnerabilities.take(20).map((v) => CveModel.fromJson(Map<String, dynamic>.from(v))).toList();
          return _cachedCves;
        }
      }
    } catch (backupErr) {
      developer.log('CIRCL backup failed.', name: 'CVE-Intel', error: backupErr);
    }

    // Offline fallback: Return last cached data so the UI never stops or breaks
    if (_cachedCves.isNotEmpty) {
      return _cachedCves;
    }

    _cachedCves = [
      CveModel(
        id: 'CVE-2024-3094',
        description: 'XZ Utils backdoor allowing unauthorized SSH remote code execution.',
        severity: 'CRITICAL',
        score: 10.0,
        publishedDate: DateTime(2024, 3, 29),
        isKev: true,
      ),
      CveModel(
        id: 'CVE-2024-21626',
        description: 'runc container breakout vulnerability via file descriptor leak.',
        severity: 'HIGH',
        score: 8.6,
        publishedDate: DateTime(2024, 1, 31),
        isKev: true,
      ),
      CveModel(
        id: 'CVE-2023-4863',
        description: 'WebP Heap Buffer Overflow in libwebp image rendering library.',
        severity: 'HIGH',
        score: 8.8,
        publishedDate: DateTime(2023, 9, 12),
        isKev: true,
      ),
    ];
    return _cachedCves;
  }

  /// Direct CVE details lookup from Shodan CVEDB
  Future<CveModel?> getCveDetails(String cveId) async {
    try {
      final response = await _dio.get(
        'https://cvedb.shodan.io/cve/$cveId',
        options: Options(receiveTimeout: const Duration(seconds: 6)),
      );
      if (response.statusCode == 200 && response.data != null) {
        return CveModel.fromJson(Map<String, dynamic>.from(response.data));
      }
    } catch (_) {}
    return null;
  }
}
