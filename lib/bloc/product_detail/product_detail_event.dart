part of 'product_detail_bloc.dart';

sealed class ProductDetailEvent extends Equatable {
  const ProductDetailEvent();
  @override
  List<Object?> get props => [];
}

/// Initial load and the error view's retry.
final class ProductDetailRequested extends ProductDetailEvent {
  final int productId;
  const ProductDetailRequested(this.productId);
  @override
  List<Object?> get props => [productId];
}
