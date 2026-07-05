import 'package:flutter/material.dart';

import '../../../core/theme/flow_mova_colors.dart';
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

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: FlowMovaLogo(width: 150),
                      ),
                      const SizedBox(height: 24),
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
                        style: textTheme.bodyLarge?.copyWith(
                          color: FlowMovaColors.slate,
                        ),
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
    );
  }
}
