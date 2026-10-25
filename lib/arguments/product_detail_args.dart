class ProductDetailArgs {
  final int productId;

  /// Carried from the tapped card so the header paints immediately (and the
  /// Hero has something to fly) instead of showing a spinner over the whole
  /// screen while the detail request runs.
  final String? title;
  final String? imageUrl;

  const ProductDetailArgs({required this.productId, this.title, this.imageUrl});
}
