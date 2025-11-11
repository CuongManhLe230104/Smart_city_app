class EventBannerModel {
  final int id;
  final String title;
  final String? description;
  final String imageUrl;

  EventBannerModel({
    required this.id,
    required this.title,
    this.description,
    required this.imageUrl,
  });

  factory EventBannerModel.fromJson(Map<String, dynamic> json) {
    return EventBannerModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['imageUrl'],
    );
  }
}
