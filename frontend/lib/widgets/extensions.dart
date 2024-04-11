// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:flutter/material.dart';

extension WidgetQoL on Widget {
  Padding padded({double? all, double? left, double? top, double? right, double? bottom, double? horizontal, double? vertical}) {
    if (all != null) return Padding(padding: EdgeInsets.all(all), child: this);
    else return Padding( padding: EdgeInsets.fromLTRB((left ?? horizontal) ?? 0, (top ?? vertical) ?? 0,
        (right ?? horizontal) ?? 0, (bottom ?? vertical) ?? 0), child: this);
  }

  Center centered({double? widthFactor, double? heightFactor}) =>
      Center(widthFactor: widthFactor, heightFactor: heightFactor, child: this);

  Expanded expanded({Key? key,int flex = 1}) {
    return Expanded(key: key, flex: flex, child: this);
  }

  Widget backgroundColor(Color color) => ColoredBox(color: color, child: this);

  ConstrainedBox constrained({double? minWidth, double? maxWidth, double? minHeight, double? maxHeight}) {
    return ConstrainedBox(constraints: BoxConstraints(minWidth: minWidth ?? 0, maxWidth: maxWidth ?? double.infinity,
        minHeight: minHeight ?? 0, maxHeight: maxHeight ?? double.infinity), child: this);
  }
}

extension BuildContextQoL on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  TextStyle get displayLarge => textTheme.displayLarge!;
  TextStyle get displayMedium => textTheme.displayMedium!;
  TextStyle get displaySmall => textTheme.displaySmall!;
  TextStyle get headlineLarge => textTheme.headlineLarge!;
  TextStyle get headlineMedium => textTheme.headlineMedium!;
  TextStyle get headlineSmall => textTheme.headlineSmall!;
  TextStyle get titleLarge => textTheme.titleLarge!;
  TextStyle get titleMedium => textTheme.titleMedium!;
  TextStyle get titleSmall => textTheme.titleSmall!;
  TextStyle get bodyLarge => textTheme.bodyLarge!;
  TextStyle get bodyMedium => textTheme.bodyMedium!;
  TextStyle get bodySmall => textTheme.bodySmall!;
  TextStyle get labelLarge => textTheme.labelLarge!;
  TextStyle get labelMedium => textTheme.labelMedium!;
  TextStyle get labelSmall => textTheme.labelSmall!;

  Color get primaryColor => colorScheme.primary;
  Color get secondaryColor => colorScheme.secondary;
  Color get tertiaryColor => colorScheme.tertiary;
  Color get disabledColor => Theme.of(this).disabledColor;
  Color get errorColor => colorScheme.error;

  double get margin => MediaQuery.sizeOf(this).width <= 400 ? 16 : 32;
}
