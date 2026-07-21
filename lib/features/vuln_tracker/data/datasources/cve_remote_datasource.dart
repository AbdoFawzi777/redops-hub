import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import '../models/cve_model.dart';

class CveRemoteDataSource {
  final Dio _dio = Dio();

  Future<List<CveModel>> getLatestCves() async {
    try {
      // 1. Try fetching from NIST NVD API (Latest 20 vulnerabilities)
      final response = await _dio.get(
        'https://services.nvd.nist.gov/rest/json/cves/2.0',
        queryParameters: {
          'resultsPerPage': 20,
          'startIndex': 0,
        },
        options: Options(receiveTimeout: const Duration(seconds: 8)),
      );

      if (response.statusCode == 200) {
        final List vulnerabilities = response.data['vulnerabilities'] ?? [];
        return vulnerabilities.map((v) => CveModel.fromJson(v)).toList();
      } else {
        throw Exception('Throttled or failed response');
      }
    } catch (e) {
      developer.log(
        'NIST NVD failed, switching to CIRCL CVE Backup API.',
        name: 'CVE-Intel',
        error: e,
      );
      try {
        // 2. Fallback to CIRCL CVE Search API (latest 30 vulnerabilities)
        final response = await _dio.get(
          'https://cve.circl.lu/api/last',
          options: Options(receiveTimeout: const Duration(seconds: 10)),
        );

        if (response.statusCode == 200 && response.data is List) {
          final List vulnerabilities = response.data;
          // Return up to 20 latest cves
          return vulnerabilities.take(20).map((v) => CveModel.fromJson(v)).toList();
        } else {
          throw Exception('Failed to connect to CIRCL backup');
        }
      } catch (backupErr) {
        throw Exception('All CVE sources unavailable. Error: $backupErr');
      }
    }
  }
}
