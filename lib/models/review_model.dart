import 'package:equatable/equatable.dart';

class ReviewModel extends Equatable {
  final int rating;
  final String comment;
  final String reviewerName;
  final DateTime? date;

  const ReviewModel({
    required this.rating,
    required this.comment,
    required this.reviewerName,
    this.date,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'] as String?;
    return ReviewModel(
      rating: (json['rating'] as num?)?.round() ?? 0,
      comment: json['comment'] as String? ?? '',
      reviewerName: json['reviewerName'] as String? ?? 'Anonymous',
      date: rawDate == null ? null : DateTime.tryParse(rawDate),
    );
  }

  @override
  List<Object?> get props => [rating, comment, reviewerName, date];
}
