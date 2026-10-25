import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:product_explorer/api_controller/product_api_controller.dart';
import 'package:product_explorer/api_controller/product_detail_api_controller.dart';
import 'package:product_explorer/arguments/product_detail_args.dart';
import 'package:product_explorer/bloc/product_detail/product_detail_bloc.dart';
import 'package:product_explorer/bloc/products/products_bloc.dart';
import 'package:product_explorer/view/product_detail/product_detail_screen.dart';
import 'package:product_explorer/view/products/products_screen.dart';
import 'package:product_explorer/view/splash_screen.dart';
part 'package:product_explorer/routes/app-routes.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Extract arguments if passed
    final args = settings.arguments;

    switch (settings.name) {
      case AppRoutes.splashScreen:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      // Feature blocs are created here, not in main, so each one is disposed
      // with its route instead of outliving the screen holding stale data.
      case AppRoutes.productsScreen:
        return MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (_) =>
                ProductsBloc(context.read<ProductApiController>())
                  ..add(const ProductsStarted()),
            child: const ProductsScreen(),
          ),
        );

      case AppRoutes.productDetailScreen:
        if (args is! ProductDetailArgs) return _errorRoute();
        return MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (_) =>
                ProductDetailBloc(context.read<ProductDetailApiController>())
                  ..add(ProductDetailRequested(args.productId)),
            child: ProductDetailScreen(args: args),
          ),
        );

      default:
        // Handle entirely unknown routes (404 page)
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) {
        return Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: const Center(child: Text('Page not found!')),
        );
      },
    );
  }
}
