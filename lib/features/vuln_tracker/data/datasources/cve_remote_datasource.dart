import 'package:dio/dio.dart';
import '../models/cve_model.dart';

class CveRemoteDataSource {
  final Dio _dio = Dio();

  Future<List<CveModel>> getLatestCves() async {
    try {
      // Fetching from NIST NVD API (Latest 20 vulnerabilities)
      final response = await _dio.get(
        'https://services.nvd.nist.gov/rest/json/cves/2.0',
        queryParameters: {
          'resultsPerPage': 20,
          'startIndex': 0,
        },
      );

      if (response.statusCode == 200) {
        final List vulnerabilities = response.data['vulnerabilities'];
        return vulnerabilities.map((v) => CveModel.fromJson(v)).toList();
      } else {
        throw Exception('Failed to fetch CVE data');
      }
    } catch (e) {
      throw Exception('Error connecting to CVE Intel: $e');
    }
  }
}
