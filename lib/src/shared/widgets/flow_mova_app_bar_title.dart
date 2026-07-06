import 'package:flutter/material.dart';

import '../../core/theme/flow_mova_colors.dart';
import 'flow_mova_logo.dart';

class FlowMovaAppBarTitle extends StatelessWidget {
  const FlowMovaAppBarTitle({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const FlowMovaLogo(
          variant: FlowMovaLogoVariant.mark,
          width: 34,
          height: 34,
        ),
        const SizedBox(width: 10),
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
