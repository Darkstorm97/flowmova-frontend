import 'package:flutter/widgets.dart';

import '../../core/assets/flow_mova_assets.dart';

enum FlowMovaLogoVariant { withText, mark, markMonochrome, appIcon }

class FlowMovaLogo extends StatelessWidget {
  const FlowMovaLogo({
    this.variant = FlowMovaLogoVariant.withText,
    this.width,
    super.key,
  });

  final FlowMovaLogoVariant variant;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      switch (variant) {
        FlowMovaLogoVariant.withText => FlowMovaAssets.logoWithTextColor,
        FlowMovaLogoVariant.mark => FlowMovaAssets.logoMarkColor,
        FlowMovaLogoVariant.markMonochrome => FlowMovaAssets.logoMarkMonochrome,
        FlowMovaLogoVariant.appIcon => FlowMovaAssets.appIconColor,
      },
      width: width,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}
