class NewsModel {
  final String title;
  final String source;
  final String url;
  final DateTime date;
  final String category;

  NewsModel({
    required this.title,
    required this.source,
    required this.url,
    required this.date,
    this.category = 'GLOBAL',
  });
}
