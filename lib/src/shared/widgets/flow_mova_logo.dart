import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/assets/flow_mova_assets.dart';

enum FlowMovaLogoVariant { withText, mark, markMonochrome, appIcon }

class FlowMovaLogo extends StatelessWidget {
  const FlowMovaLogo({
    this.variant = FlowMovaLogoVariant.withText,
    this.width,
    this.height,
    super.key,
  });

  final FlowMovaLogoVariant variant;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      switch (variant) {
        FlowMovaLogoVariant.withText => FlowMovaAssets.logoWithTextColor,
        FlowMovaLogoVariant.mark => FlowMovaAssets.logoMarkColor,
        FlowMovaLogoVariant.markMonochrome => FlowMovaAssets.logoMarkMonochrome,
        FlowMovaLogoVariant.appIcon => FlowMovaAssets.appIconColor,
      },
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }
}
