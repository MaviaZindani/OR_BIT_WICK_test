/// Sort options offered by the sort sheet. Each maps straight onto DummyJSON's
/// `sortBy` / `order` query params, which every list endpoint (browse,
/// category and search) accepts, so one enum drives all three.
enum ProductSort {
  relevance('Relevance', null, null),
  priceLowToHigh('Price: Low to High', 'price', 'asc'),
  priceHighToLow('Price: High to Low', 'price', 'desc'),
  ratingHighToLow('Top Rated', 'rating', 'desc'),
  titleAToZ('Name: A to Z', 'title', 'asc');

  const ProductSort(this.label, this.sortBy, this.order);

  final String label;
  final String? sortBy;
  final String? order;

  /// Empty for [relevance], so the server keeps its natural order.
  Map<String, String> get queryParams =>
      sortBy == null ? const {} : {'sortBy': sortBy!, 'order': order!};
}
