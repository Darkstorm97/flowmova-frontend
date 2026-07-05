import 'package:flutter/material.dart';

import '../../../shared/widgets/flow_mova_app_shell.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FlowMovaAppShell(child: _HomeContent());
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FlowMova',
          style: textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Text(
          'Fluidifier la relation entre les entreprises et leurs clients.',
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: 32),
        const _HomeActionCard(
          title: 'Parcours client',
          description:
              'Rechercher une entreprise, choisir un service et creer un ticket.',
          actionLabel: 'Explorer',
        ),
        const SizedBox(height: 12),
        const _HomeActionCard(
          title: 'Espace entreprise',
          description:
              'Se connecter pour gerer ses entreprises, services et demandes.',
          actionLabel: 'Se connecter',
        ),
      ],
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.title,
    required this.description,
    required this.actionLabel,
  });

  final String title;
  final String description;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(description),
                ],
              ),
            ),
            const SizedBox(width: 16),
            FilledButton(onPressed: () {}, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
