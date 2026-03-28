import 'package:flutter/material.dart';

class AppSpace {
  // The 8pt Grid Constants
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 20.0; // Standard margin for phones
  static const double l = 24.0; // Standard margin for tablets
  static const double xl = 32.0;

  /// Returns the appropriate margin based on screen width (Breakpoint)
  static double getPageMargin(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 600) return l; // Tablet gets 24px
    return m; // Phone gets 16px
  }

  /// Returns the top padding including the Safe Area
  static double getSafeTop(BuildContext context) {
    return MediaQuery.of(context).padding.top + s;
  }
}
