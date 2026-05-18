import 'package:flutter/material.dart';

const String kAppIconAssetPath = 'assets/app_icon/app_icon_source.png';

class AppBrandMark extends StatelessWidget {
  const AppBrandMark({
    super.key,
    required this.slot,
    this.borderRadius = 8,
  });

  final double slot;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final innerW = slot * 0.95;
    final innerH = slot;
    return SizedBox(
      width: slot,
      height: slot,
      child: Center(
        child: SizedBox(
          width: innerW,
          height: innerH,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Image.asset(
              kAppIconAssetPath,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ),
    );
  }
}
