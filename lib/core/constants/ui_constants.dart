import 'package:flutter/material.dart';

class UI {
  UI._();

  // Radii
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 999;

  // Spacing
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;

  // Padding
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: 20);

  // Motion
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
}
