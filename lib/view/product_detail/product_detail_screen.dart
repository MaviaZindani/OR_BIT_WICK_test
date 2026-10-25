import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:product_explorer/arguments/product_detail_args.dart';
import 'package:product_explorer/bloc/product_detail/product_detail_bloc.dart';
import 'package:product_explorer/constant/app_colors.dart';
import 'package:product_explorer/constant/data_const.dart';
import 'package:product_explorer/constant/design_const.dart';
import 'package:product_explorer/generic_widgets/states/app_state_views.dart';
import 'package:product_explorer/view/product_detail/widgets/detail_image_gallery.dart';
import 'package:product_explorer/view/product_detail/widgets/detail_info_section.dart';

/// Product detail. The gallery slot is painted from the tapped card's
/// thumbnail straight away (and receives the Hero), so only the text block
/// below it waits on the request. Splits into a side-by-side layout from
/// 700dp, via `LayoutBuilder` rather than `Orientation` so a portrait tablet
/// also gets it.
class ProductDetailScreen extends StatelessWidget {
  final ProductDetailArgs args;

  const ProductDetailScreen({super.key, required this.args});

  static const double _wideBreakpoint = 700;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: Text(
          args.title ?? 'Product',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.sectionHeading,
        ),
      ),
      body: BlocBuilder<ProductDetailBloc, ProductDetailState>(
        builder: (context, state) {
          final gallery = DetailImageGallery(
            productId: args.productId,
            images: switch (state) {
              ProductDetailLoaded(:final detail) => detail.product.gallery,
              _ => [if (args.imageUrl != null) args.imageUrl!],
            },
          );

          final Widget body = switch (state) {
            ProductDetailInitial() || ProductDetailLoading() => const Padding(
              padding: EdgeInsets.only(top: 48),
              child: AppLoader(),
            ),
            ProductDetailError(:final message) => Padding(
              padding: const EdgeInsets.only(top: 24),
              child: AppErrorView(
                message: message,
                onRetry: () => context.read<ProductDetailBloc>().add(
                  ProductDetailRequested(args.productId),
                ),
              ),
            ),
            ProductDetailLoaded(:final detail) => DetailInfoSection(
              detail: detail,
            ),
          };

          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= _wideBreakpoint) {
                return _WideLayout(gallery: gallery, body: body);
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.only(
                  bottom: DataConst.kScreenBottomPadding * 3,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AspectRatio(aspectRatio: 1.1, child: gallery),
                    body,
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _WideLayout extends StatelessWidget {
  final Widget gallery;
  final Widget body;

  const _WideLayout({required this.gallery, required this.body});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.all(DataConst.kScreenHorizontalPadding * 2),
            child: AspectRatio(aspectRatio: 1, child: gallery),
          ),
        ),
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              bottom: DataConst.kScreenBottomPadding * 3,
            ),
            child: body,
          ),
        ),
      ],
    );
  }
}
