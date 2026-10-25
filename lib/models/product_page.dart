import 'package:equatable/equatable.dart';
import 'package:product_explorer/models/product_model.dart';

/// A page of DummyJSON list results. [total] is the server's count across all
/// pages, which is what the "N products" header reports - `products` alone is
/// capped at the page size.
class ProductPage extends Equatable {
  final List<ProductModel> products;
  final int total;
  final int skip;
  final int limit;

  const ProductPage({
    this.products = const [],
    this.total = 0,
    this.skip = 0,
    this.limit = 0,
  });

  factory ProductPage.fromJson(Map<String, dynamic> json) => ProductPage(
    products:
        (json['products'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(ProductModel.fromJson)
            .toList() ??
        const [],
    total: json['total'] as int? ?? 0,
    skip: json['skip'] as int? ?? 0,
    limit: json['limit'] as int? ?? 0,
  );

  /// Based on what actually arrived rather than `limit`, because a request
  /// for `limit=0` ("everything") echoes `limit` back as the total.
  bool get hasMore => skip + products.length < total;

  /// Offset the next page should ask for.
  int get nextSkip => skip + products.length;

  @override
  List<Object?> get props => [products, total, skip, limit];
}
