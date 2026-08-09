import 'package:flutter/material.dart';

class Responsive {
  static const double mobile = 700;
  static const double tablet = 1100;

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return width >= mobile && width < tablet;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tablet;
  }

  static int gridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < mobile) {
      return 1;
    }

    if (width < tablet) {
      return 2;
    }

    return 4;
  }

  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < mobile) {
      return 16;
    }

    if (width < tablet) {
      return 22;
    }

    return 30;
  }

  static double spacing(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < mobile) {
      return 12;
    }

    if (width < tablet) {
      return 16;
    }

    return 20;
  }
}