class Payload {
  final String title;
  final String category;
  final String description;
  final String code;
  final String source; // e.g., 'LOLBAS', 'GTFOBins', 'Custom'

  Payload({
    required this.title,
    required this.category,
    required this.description,
    required this.code,
    required this.source,
  });
}
