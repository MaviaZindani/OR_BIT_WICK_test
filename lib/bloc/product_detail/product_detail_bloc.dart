import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:product_explorer/api_controller/product_detail_api_controller.dart';
import 'package:product_explorer/models/product_detail_model.dart';

part 'product_detail_event.dart';
part 'product_detail_state.dart';

class ProductDetailBloc extends Bloc<ProductDetailEvent, ProductDetailState> {
  final ProductDetailApiController controller;

  ProductDetailBloc(this.controller) : super(const ProductDetailInitial()) {
    // restartable(): a retry tapped while the first request is still hanging
    // replaces it instead of racing it.
    on<ProductDetailRequested>(_onRequested, transformer: restartable());
  }

  Future<void> _onRequested(
    ProductDetailRequested event,
    Emitter<ProductDetailState> emit,
  ) async {
    emit(const ProductDetailLoading());
    try {
      final detail = await controller.getProduct(event.productId);
      if (emit.isDone) return;
      emit(ProductDetailLoaded(detail));
    } catch (e) {
      if (emit.isDone) return;
      emit(ProductDetailError(e.toString()));
    }
  }
}
