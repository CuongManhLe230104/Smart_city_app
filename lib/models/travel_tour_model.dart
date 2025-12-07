class TravelTour {
  final int id;
  final String nameTour;
  final String tourType;
  final String content;
  final String timeline;
  final double price;
  final int maxPeople;
  final String duration;
  final String? coverImageUrl;
  final String? galleryImageUrls; // Chuỗi JSON của list URLs
  final int userId;

  TravelTour({
    required this.id,
    required this.nameTour,
    required this.tourType,
    required this.content,
    required this.timeline,
    required this.price,
    required this.maxPeople,
    required this.duration,
    required this.userId,
    this.coverImageUrl,
    this.galleryImageUrls,
  });

  // Factory constructor để ánh xạ từ JSON (API response)
  factory TravelTour.fromJson(Map<String, dynamic> json) {
    return TravelTour(
      id: json['id'] as int,
      nameTour: json['nameTour'] as String,
      tourType: json['tourType'] as String,
      content: json['content'] as String? ?? '',
      timeline: json['timeline'] as String? ?? '',
      price: json['price'] is int
          ? (json['price'] as int).toDouble()
          : json['price'] as double,
      maxPeople: json['maxPeople'] as int,
      duration: json['duration'] as String? ?? '',
      userId: json['userId'] as int,
      coverImageUrl: json['coverImageUrl'] as String?,
      galleryImageUrls: json['galleryImageUrls'] as String?,
    );
  }
}
