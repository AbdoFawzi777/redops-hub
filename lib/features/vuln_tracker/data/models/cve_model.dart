class CveModel {
  final String id;
  final String description;
  final String severity;
  final double? score;
  final DateTime publishedDate;

  CveModel({
    required this.id,
    required this.description,
    required this.severity,
    this.score,
    required this.publishedDate,
  });

  factory CveModel.fromJson(Map<String, dynamic> json) {
    // Parsing logic for NIST NVD API format
    final cve = json['cve'];
    final metrics = cve['metrics']?['cvssMetricV31']?[0]?['cvssData'];
    
    return CveModel(
      id: cve['id'] ?? 'UNKNOWN',
      description: cve['descriptions']?[0]?['value'] ?? 'No description available',
      severity: metrics?['baseSeverity'] ?? 'UNKNOWN',
      score: metrics?['baseScore']?.toDouble(),
      publishedDate: DateTime.parse(cve['published']),
    );
  }
}
