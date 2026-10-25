part of 'product_detail_bloc.dart';

/// Sealed, unlike [ProductsState]: a detail screen is one request with one
/// outcome, so exhaustive `switch` in the view is clearer than status flags.
sealed class ProductDetailState extends Equatable {
  const ProductDetailState();
  @override
  List<Object?> get props => [];
}

final class ProductDetailInitial extends ProductDetailState {
  const ProductDetailInitial();
}

final class ProductDetailLoading extends ProductDetailState {
  const ProductDetailLoading();
}

final class ProductDetailLoaded extends ProductDetailState {
  final ProductDetailModel detail;
  const ProductDetailLoaded(this.detail);
  @override
  List<Object?> get props => [detail];
}

final class ProductDetailError extends ProductDetailState {
  final String message;
  const ProductDetailError(this.message);
  @override
  List<Object?> get props => [message];
}
