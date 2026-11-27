import 'package:flutter/widgets.dart';

enum ScreenSize { compact, medium, expanded }

class Responsive {
  Responsive._();

  static const double mediumBreakpoint = 600;
  static const double expandedBreakpoint = 1000;

  static ScreenSize of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= expandedBreakpoint) return ScreenSize.expanded;
    if (width >= mediumBreakpoint) return ScreenSize.medium;
    return ScreenSize.compact;
  }
}
