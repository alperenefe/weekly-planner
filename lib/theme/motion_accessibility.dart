import 'package:flutter/material.dart';

abstract final class MotionAccessibility {
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  static Duration dur(BuildContext context, Duration normal) =>
      reduced(context) ? Duration.zero : normal;
}
