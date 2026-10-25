part of 'products_bloc.dart';

enum ProductsStatus { idle, loading, success, failure }

/// One flat state rather than a sealed hierarchy: the category row and the
/// product grid are concurrent - categories load once and must survive every
/// keystroke, chip tap and page load that replaces the products.
class ProductsState extends Equatable {
  final List<CategoryModel> categories;
  final ProductsStatus categoryStatus;

  final String query;
  final String? selectedCategory;
  final ProductSort sort;

  final List<ProductModel> products;
  final int total;
  final ProductsStatus status;
  final bool hasMore;
  final bool isLoadingMore;

  /// The last page request failed; the grid shows a retry footer instead of
  /// silently stopping.
  final bool loadMoreFailed;

  /// Set alongside [ProductsStatus.failure], and also on a failed refresh
  /// while the previous products stay on screen (shown as a snackbar).
  final String? errorMessage;

  const ProductsState({
    this.categories = const [],
    this.categoryStatus = ProductsStatus.idle,
    this.query = '',
    this.selectedCategory,
    this.sort = ProductSort.relevance,
    this.products = const [],
    this.total = 0,
    this.status = ProductsStatus.idle,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
    this.errorMessage,
  });

  bool get isSearching => query.trim().isNotEmpty;

  bool get hasActiveFilters =>
      isSearching || selectedCategory != null || sort != ProductSort.relevance;

  /// Chip badge count on the sort / filter button.
  int get activeFilterCount =>
      (selectedCategory != null ? 1 : 0) +
      (sort != ProductSort.relevance ? 1 : 0);

  /// Everything a fetch depends on. A handler snapshots this before awaiting
  /// and drops its response if the user has moved on since.
  ProductsFilters get filters =>
      ProductsFilters(query: query.trim(), category: selectedCategory, sort: sort);

  ProductsState copyWith({
    List<CategoryModel>? categories,
    ProductsStatus? categoryStatus,
    String? query,
    String? selectedCategory,
    bool clearSelectedCategory = false,
    ProductSort? sort,
    List<ProductModel>? products,
    int? total,
    ProductsStatus? status,
    bool? hasMore,
    bool? isLoadingMore,
    bool? loadMoreFailed,
    String? errorMessage,
  }) => ProductsState(
    categories: categories ?? this.categories,
    categoryStatus: categoryStatus ?? this.categoryStatus,
    query: query ?? this.query,
    selectedCategory: clearSelectedCategory
        ? null
        : (selectedCategory ?? this.selectedCategory),
    sort: sort ?? this.sort,
    products: products ?? this.products,
    total: total ?? this.total,
    status: status ?? this.status,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    // Deliberately not carried over: an error belongs to one emission.
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [
    categories,
    categoryStatus,
    query,
    selectedCategory,
    sort,
    products,
    total,
    status,
    hasMore,
    isLoadingMore,
    loadMoreFailed,
    errorMessage,
  ];
}

class ProductsFilters extends Equatable {
  final String query;
  final String? category;
  final ProductSort sort;

  const ProductsFilters({
    this.query = '',
    this.category,
    this.sort = ProductSort.relevance,
  });

  bool get isSearching => query.isNotEmpty;

  @override
  List<Object?> get props => [query, category, sort];
}
