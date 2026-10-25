import 'package:equatable/equatable.dart';
import 'package:product_explorer/models/product_model.dart';
import 'package:product_explorer/models/review_model.dart';

/// Everything `/products/{id}` adds on top of the list payload. Wraps a
/// [ProductModel] rather than extending it so the grid and the detail screen
/// share one price / discount / stock vocabulary.
class ProductDetailModel extends Equatable {
  final ProductModel product;
  final String sku;
  final String warrantyInformation;
  final String shippingInformation;
  final String returnPolicy;
  final int minimumOrderQuantity;
  final double weight;
  final Dimensions? dimensions;
  final List<ReviewModel> reviews;

  const ProductDetailModel({
    required this.product,
    this.sku = '',
    this.warrantyInformation = '',
    this.shippingInformation = '',
    this.returnPolicy = '',
    this.minimumOrderQuantity = 1,
    this.weight = 0,
    this.dimensions,
    this.reviews = const [],
  });

  factory ProductDetailModel.fromJson(Map<String, dynamic> json) {
    final dims = json['dimensions'];
    return ProductDetailModel(
      product: ProductModel.fromJson(json),
      sku: json['sku'] as String? ?? '',
      warrantyInformation: json['warrantyInformation'] as String? ?? '',
      shippingInformation: json['shippingInformation'] as String? ?? '',
      returnPolicy: json['returnPolicy'] as String? ?? '',
      minimumOrderQuantity: json['minimumOrderQuantity'] as int? ?? 1,
      weight: (json['weight'] as num?)?.toDouble() ?? 0,
      dimensions: dims is Map<String, dynamic> ? Dimensions.fromJson(dims) : null,
      reviews:
          (json['reviews'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(ReviewModel.fromJson)
              .toList() ??
          const [],
    );
  }

  /// Mean of the review ratings, or the product's own rating when there are
  /// no reviews to average.
  double get averageReviewRating => reviews.isEmpty
      ? product.rating
      : reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;

  @override
  List<Object?> get props => [product, sku, reviews, dimensions];
}

class Dimensions extends Equatable {
  final double width;
  final double height;
  final double depth;

  const Dimensions({this.width = 0, this.height = 0, this.depth = 0});

  factory Dimensions.fromJson(Map<String, dynamic> json) => Dimensions(
    width: (json['width'] as num?)?.toDouble() ?? 0,
    height: (json['height'] as num?)?.toDouble() ?? 0,
    depth: (json['depth'] as num?)?.toDouble() ?? 0,
  );

  /// "15.1 × 13.1 × 23 cm"
  String get label =>
      '${_trim(width)} × ${_trim(height)} × ${_trim(depth)} cm';

  /// One decimal, with a trailing ".0" dropped: 22.99 -> "23", 15.14 -> "15.1".
  static String _trim(double v) {
    final fixed = v.toStringAsFixed(1);
    return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
  }

  @override
  List<Object?> get props => [width, height, depth];
}
