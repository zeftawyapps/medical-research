import 'package:flutter/material.dart';

class ResponsiveLayout {
  static const double mobileBreakpoint = 650;
  static const double tabletBreakpoint = 1050;
  static const double desktopBreakpoint = 1400;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= mobileBreakpoint &&
      MediaQuery.sizeOf(context).width < tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  static bool isWideDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopBreakpoint;

  static int gridCrossAxisCount(BuildContext context, {int mobile = 1, int tablet = 2, int desktop = 3, int wide = 4}) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktopBreakpoint) return wide;
    if (width >= tabletBreakpoint) return desktop;
    if (width >= mobileBreakpoint) return tablet;
    return mobile;
  }

  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  static bool isCompactHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height < 550;

  static bool isMobileOrLandscape(BuildContext context) =>
      isMobile(context) || isCompactHeight(context);

  /// WhatsApp-like scroll padding that ensures any active TextField scrolls
  /// safely into clear reading view right above the on-screen keyboard in landscape mode.
  static EdgeInsets textFieldScrollPadding(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.orientation == Orientation.landscape || media.size.height < 550) {
      return const EdgeInsets.only(bottom: 120, top: 30);
    }
    return const EdgeInsets.all(20.0);
  }

  static double horizontalPadding(BuildContext context) {
    if (isWideDesktop(context)) return 32;
    if (isDesktop(context)) return 24;
    if (isTablet(context)) return 20;
    return 16;
  }
}
