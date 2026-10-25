part of 'products_bloc.dart';

sealed class ProductsEvent extends Equatable {
  const ProductsEvent();
  @override
  List<Object?> get props => [];
}

/// First load: kicks off the category row and the first page together.
final class ProductsStarted extends ProductsEvent {
  const ProductsStarted();
}

/// Loads (or retries) the category chips. Separate from [ProductsStarted] so
/// a failed category fetch can be retried without reloading the grid.
final class ProductsCategoriesRequested extends ProductsEvent {
  const ProductsCategoriesRequested();
}

/// A keystroke. Debounced and restartable, so only the latest one survives.
final class ProductsQueryChanged extends ProductsEvent {
  final String query;
  const ProductsQueryChanged(this.query);
  @override
  List<Object?> get props => [query];
}

final class ProductsSearchCleared extends ProductsEvent {
  const ProductsSearchCleared();
}

/// `null` selects "All". Tapping the already-selected chip also clears it.
final class ProductsCategorySelected extends ProductsEvent {
  final String? slug;
  const ProductsCategorySelected(this.slug);
  @override
  List<Object?> get props => [slug];
}

final class ProductsSortChanged extends ProductsEvent {
  final ProductSort sort;
  const ProductsSortChanged(this.sort);
  @override
  List<Object?> get props => [sort];
}

/// Resets query, category and sort in one step - the empty state's button.
final class ProductsFiltersCleared extends ProductsEvent {
  const ProductsFiltersCleared();
}

/// Infinite scroll. Ignored while a page is in flight or in search mode,
/// where the whole match set is already on screen.
final class ProductsLoadMoreRequested extends ProductsEvent {
  const ProductsLoadMoreRequested();
}

/// Pull to refresh. Re-runs the current filters without blanking the grid.
final class ProductsRefreshed extends ProductsEvent {
  const ProductsRefreshed();
}
