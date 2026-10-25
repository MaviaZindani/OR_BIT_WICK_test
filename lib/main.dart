import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:product_explorer/api_controller/product_api_controller.dart';
import 'package:product_explorer/api_controller/product_detail_api_controller.dart';
import 'package:product_explorer/constant/app_colors.dart';
import 'package:product_explorer/routes/app_pages.dart';
import 'package:product_explorer/service/api_service/api_links.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ApiLinks.init(environment: currentEnvironment);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => const ProductApiController()),
        RepositoryProvider(create: (_) => const ProductDetailApiController()),
      ],
      child: MaterialApp(
        onGenerateRoute: RouteGenerator.generateRoute,
        initialRoute: AppRoutes.splashScreen,
        title: 'Product Explorer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.screenBackground,
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          textTheme: GoogleFonts.poppinsTextTheme(),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.background,
            surfaceTintColor: AppColors.background,
            elevation: 0,
            scrolledUnderElevation: 0,
            iconTheme: IconThemeData(color: AppColors.darkText),
          ),
          snackBarTheme: const SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
          ),
        ),
      ),
    );
  }
}
