import 'package:flutter/material.dart';

import '../../../core/theme/flow_mova_colors.dart';
import '../../../core/theme/flow_mova_radii.dart';
import '../../../shared/widgets/flow_mova_logo.dart';

class AuthFormShell extends StatelessWidget {
  const AuthFormShell({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final mediaQuery = MediaQuery.of(context);
    final wideLayout = mediaQuery.size.width >= 840;

    return Scaffold(
      appBar: AppBar(
        title: const FlowMovaLogo(
          variant: FlowMovaLogoVariant.mark,
          width: 44,
          height: 44,
        ),
      ),
      body: SafeArea(
        child: ColoredBox(
          color: FlowMovaColors.cloud,
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: wideLayout ? 32 : 20,
                vertical: 24,
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 360),
                curve: Curves.easeOutCubic,
                builder: (context, value, animatedChild) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - value) * 14),
                      child: animatedChild,
                    ),
                  );
                },
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: wideLayout ? 980 : 460),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: FlowMovaColors.white,
                      border: Border.all(color: FlowMovaColors.border),
                      borderRadius: BorderRadius.circular(FlowMovaRadii.large),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(wideLayout ? 28 : 20),
                      child: wideLayout
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: _AuthIntro(
                                    title: title,
                                    subtitle: subtitle,
                                    textTheme: textTheme,
                                  ),
                                ),
                                const SizedBox(width: 32),
                                SizedBox(width: 420, child: child),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _AuthIntro(
                                  title: title,
                                  subtitle: subtitle,
                                  textTheme: textTheme,
                                ),
                                const SizedBox(height: 24),
                                child,
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthIntro extends StatelessWidget {
  const _AuthIntro({
    required this.title,
    required this.subtitle,
    required this.textTheme,
  });

  final String title;
  final String subtitle;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: FlowMovaLogo(width: 164, height: 112),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: textTheme.headlineMedium?.copyWith(
            color: FlowMovaColors.logoInk,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: textTheme.bodyLarge?.copyWith(color: FlowMovaColors.slate),
        ),
      ],
    );
  }
}
