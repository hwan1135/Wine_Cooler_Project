class Wine {
  final String title;
  final String vintage;
  final String country;
  final double price;
  final String drinkingWindow;

  Wine({
    required this.title,
    required this.vintage,
    required this.country,
    required this.price,
    required this.drinkingWindow,
  });

  factory Wine.fromJson(Map<String, dynamic> json) {
    return Wine(
      title: json['title'] ?? 'Unknown',
      vintage: json['vintage']?.toString() ?? 'N/A',
      country: json['country'] ?? 'Unknown',
      price: (json['price'] ?? 0.0).toDouble(),
      drinkingWindow: json['drinkingWindow'] ?? 'N/A',
    );
  }
}
