import 'package:flutter/material.dart';

import '../../../core/theme/flow_mova_colors.dart';
import '../../../core/theme/flow_mova_radii.dart';
import '../../../shared/widgets/flow_mova_app_shell.dart';
import '../../../shared/widgets/flow_mova_logo.dart';

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
        const FlowMovaLogo(width: 188),
        const SizedBox(height: 32),
        Text(
          'Un pont fluide entre vos clients et votre equipe.',
          style: textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Text(
          'FlowMova simplifie la creation, le suivi et le traitement des demandes client.',
          style: textTheme.titleMedium?.copyWith(color: FlowMovaColors.slate),
        ),
        const SizedBox(height: 28),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _BrandBadge(label: 'Mobile-first'),
            _BrandBadge(label: 'Tickets'),
            _BrandBadge(label: 'Services'),
          ],
        ),
        const SizedBox(height: 28),
        const _HomeActionCard(
          title: 'Parcours client',
          description:
              'Rechercher une entreprise, choisir un service et creer un ticket.',
          actionLabel: 'Explorer',
          icon: Icons.person_search_outlined,
        ),
        const SizedBox(height: 12),
        const _HomeActionCard(
          title: 'Espace entreprise',
          description:
              'Se connecter pour gerer ses entreprises, services et demandes.',
          actionLabel: 'Se connecter',
          icon: Icons.storefront_outlined,
          secondary: true,
        ),
      ],
    );
  }
}

class _BrandBadge extends StatelessWidget {
  const _BrandBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FlowMovaColors.white,
        border: Border.all(color: FlowMovaColors.border),
        borderRadius: BorderRadius.circular(FlowMovaRadii.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: FlowMovaColors.logoInk,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.icon,
    this.secondary = false,
  });

  final String title;
  final String description;
  final String actionLabel;
  final IconData icon;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final iconBox = DecoratedBox(
            decoration: BoxDecoration(
              color: secondary
                  ? FlowMovaColors.skyBlue.withValues(alpha: 0.16)
                  : colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(FlowMovaRadii.small),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(
                icon,
                color: secondary ? FlowMovaColors.skyBlue : colorScheme.primary,
              ),
            ),
          );
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: textTheme.bodyMedium?.copyWith(
                  color: FlowMovaColors.slate,
                ),
              ),
            ],
          );
          final action = secondary
              ? OutlinedButton(onPressed: () {}, child: Text(actionLabel))
              : FilledButton(onPressed: () {}, child: Text(actionLabel));

          return Padding(
            padding: const EdgeInsets.all(16),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      iconBox,
                      const SizedBox(height: 14),
                      content,
                      const SizedBox(height: 16),
                      SizedBox(width: double.infinity, child: action),
                    ],
                  )
                : Row(
                    children: [
                      iconBox,
                      const SizedBox(width: 14),
                      Expanded(child: content),
                      const SizedBox(width: 16),
                      action,
                    ],
                  ),
          );
        },
      ),
    );
  }
}
