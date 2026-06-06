class Feedback {
  final String id;
  final String userId;
  final String comments;
  final int rating;

  Feedback({
    required this.id,
    required this.userId,
    required this.comments,
    required this.rating,
  });

  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      comments: json['comments']?.toString() ?? '',
      rating: int.tryParse(json['rating'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'comments': comments,
      'rating': rating,
    };
  }
}
