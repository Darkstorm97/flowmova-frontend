import 'package:flutter/material.dart';

import '../../core/theme/flow_mova_colors.dart';
import 'flow_mova_logo.dart';

class FlowMovaAppBarTitle extends StatelessWidget {
  const FlowMovaAppBarTitle({
    required this.title,
    super.key,
    this.showLogo = true,
    this.logoSize = 30,
  });

  final String title;
  final bool showLogo;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showLogo) ...[
          FlowMovaLogo(
            variant: FlowMovaLogoVariant.mark,
            width: logoSize,
            height: logoSize,
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: FlowMovaColors.logoInk,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
