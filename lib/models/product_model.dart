import 'package:equatable/equatable.dart';

/// The fields the product grid needs. List endpoints are asked for exactly
/// these via `select=`, so the full description / reviews / dimensions block
/// only travels for the one product the user opens.
class ProductModel extends Equatable {
  final int id;
  final String title;
  final String description;
  final String category;
  final String brand;
  final double price;
  final double discountPercentage;
  final double rating;
  final int stock;
  final String availabilityStatus;
  final String? thumbnail;
  final List<String> images;
  final List<String> tags;

  const ProductModel({
    required this.id,
    required this.title,
    this.description = '',
    this.category = '',
    this.brand = '',
    this.price = 0,
    this.discountPercentage = 0,
    this.rating = 0,
    this.stock = 0,
    this.availabilityStatus = '',
    this.thumbnail,
    this.images = const [],
    this.tags = const [],
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
    id: json['id'] as int? ?? 0,
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    category: json['category'] as String? ?? '',
    brand: json['brand'] as String? ?? '',
    // Numbers arrive as int for whole values and double otherwise.
    price: (json['price'] as num?)?.toDouble() ?? 0,
    discountPercentage: (json['discountPercentage'] as num?)?.toDouble() ?? 0,
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    stock: json['stock'] as int? ?? 0,
    availabilityStatus: json['availabilityStatus'] as String? ?? '',
    thumbnail: json['thumbnail'] as String?,
    images: (json['images'] as List?)?.whereType<String>().toList() ?? const [],
    tags: (json['tags'] as List?)?.whereType<String>().toList() ?? const [],
  );

  bool get hasDiscount => discountPercentage > 0;

  /// Price after DummyJSON's `discountPercentage`, rounded to cents.
  double get discountedPrice =>
      hasDiscount ? (price * (1 - discountPercentage / 100) * 100).round() / 100 : price;

  bool get isInStock => stock > 0;

  /// Falls back to the first gallery image so a card is never blank when the
  /// payload carries no thumbnail.
  String? get imageUrl => thumbnail ?? (images.isEmpty ? null : images.first);

  /// Gallery for the detail screen; the thumbnail stands in when the detail
  /// payload has no images.
  List<String> get gallery =>
      images.isNotEmpty ? images : [?thumbnail];

  @override
  List<Object?> get props => [
    id,
    title,
    category,
    brand,
    price,
    discountPercentage,
    rating,
    stock,
    thumbnail,
  ];
}
