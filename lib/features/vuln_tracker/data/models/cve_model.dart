class CveModel {
  final String id;
  final String description;
  final String severity;
  final double? score;
  final double? epss;
  final bool isKev;
  final DateTime publishedDate;

  CveModel({
    required this.id,
    required this.description,
    required this.severity,
    this.score,
    this.epss,
    this.isKev = false,
    required this.publishedDate,
  });

  factory CveModel.fromJson(Map<String, dynamic> json) {
    // 1. Shodan CVEDB API format (Ultra-fast, zero key required)
    if (json.containsKey('cve_id')) {
      final double? cvss = json['cvss'] != null ? (json['cvss'] as num).toDouble() : null;
      final double? epssVal = json['epss'] != null ? (json['epss'] as num).toDouble() : null;
      final bool kev = json['is_kev'] == true;

      return CveModel(
        id: json['cve_id'] as String? ?? 'CVE-UNKNOWN',
        description: json['summary'] as String? ?? 'No description available',
        severity: _inferSeverity(cvss),
        score: cvss,
        epss: epssVal,
        isKev: kev,
        publishedDate: DateTime.tryParse(json['published_at'] as String? ?? '') ?? DateTime.now(),
      );
    }

    // 2. NIST NVD API format
    if (json.containsKey('cve')) {
      final cve = json['cve'];
      final metricsList = cve['metrics']?['cvssMetricV31'] ?? 
                          cve['metrics']?['cvssMetricV30'] ?? 
                          cve['metrics']?['cvssMetricV2'];
      final metrics = metricsList?[0]?['cvssData'];
      final double? baseScore = metrics?['baseScore'] != null 
          ? double.tryParse(metrics!['baseScore'].toString()) 
          : null;
      
      return CveModel(
        id: cve['id'] ?? 'UNKNOWN',
        description: cve['descriptions']?[0]?['value'] ?? 'No description available',
        severity: metrics?['baseSeverity'] ?? _inferSeverity(baseScore),
        score: baseScore,
        publishedDate: DateTime.tryParse(cve['published'] ?? '') ?? DateTime.now(),
      );
    }

    // 3. CIRCL CVE Search API format (Fallback)
    final double? cvss = json['cvss'] != null ? double.tryParse(json['cvss'].toString()) : null;
    return CveModel(
      id: json['id'] ?? 'UNKNOWN',
      description: json['summary'] ?? 'No description available',
      severity: _inferSeverity(cvss),
      score: cvss,
      publishedDate: DateTime.tryParse(json['Published'] ?? '') ?? DateTime.now(),
    );
  }

  static String _inferSeverity(double? score) {
    if (score == null) return 'UNKNOWN';
    if (score >= 9.0) return 'CRITICAL';
    if (score >= 7.0) return 'HIGH';
    if (score >= 4.0) return 'MEDIUM';
    return 'LOW';
  }
}
