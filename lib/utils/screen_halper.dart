import 'package:flutter/material.dart';

class ScreenHelper {
  static int universalSize = 375;
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom;
  }

  static double getScreenCompleteHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).height;
  }

  static double getScreenWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }

  /// Grid columns for the product list: 2 on phones, 3 from ~600dp, 4 on
  /// wide tablets / landscape.
  static int gridColumns(double width) {
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }
}
