// lib/utils/responsive_utils.dart

import 'package:flutter/material.dart';

class ResponsiveUtils {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;
  
  static late double _safeAreaHorizontal;
  static late double _safeAreaVertical;
  static late double safeBlockHorizontal;
  static late double safeBlockVertical;

  void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;

    _safeAreaHorizontal = _mediaQueryData.padding.left + _mediaQueryData.padding.right;
    _safeAreaVertical = _mediaQueryData.padding.top + _mediaQueryData.padding.bottom;
    safeBlockHorizontal = (screenWidth - _safeAreaHorizontal) / 100;
    safeBlockVertical = (screenHeight - _safeAreaVertical) / 100;
  }

  static double hp(double percentage) {
    return blockSizeVertical * percentage;
  }

  static double wp(double percentage) {
    return blockSizeHorizontal * percentage;
  }

  static double sp(double percentage) {
    return blockSizeHorizontal * percentage;
  }

  static double borderRadius(double percentage) {
    return blockSizeHorizontal * percentage;
  }

  // New method for icon sizing
  static double iconSize(double percentage) {
    return blockSizeHorizontal * percentage;
  }
}

///////////////
class AppSizes {
  static double get smallIcon => ResponsiveUtils.iconSize(4);
  static double get mediumIcon => ResponsiveUtils.iconSize(6);
  static double get largeIcon => ResponsiveUtils.iconSize(8);
}