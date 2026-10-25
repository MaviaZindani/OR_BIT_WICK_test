import 'package:http/http.dart' as http;
import 'package:product_explorer/api_controller/api_guard.dart';
import 'package:product_explorer/models/product_detail_model.dart';
import 'package:product_explorer/service/api_service/api_links.dart';
import 'package:product_explorer/service/api_service/api_services.dart';

/// The product detail screen.
class ProductDetailApiController with ApiGuard {
  final http.Client? client;

  const ProductDetailApiController({this.client});

  Future<ProductDetailModel> getProduct(int id) => guard(() async {
    final json = await ApiService.apiGetRequest(
      ApiLinks.productDetail(id),
      httpClint: client,
    );
    return ProductDetailModel.fromJson(json as Map<String, dynamic>);
  });
}
