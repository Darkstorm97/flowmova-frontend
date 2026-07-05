import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/theme/flow_mova_colors.dart';
import '../../../core/theme/flow_mova_radii.dart';
import '../../../shared/widgets/flow_mova_logo.dart';

class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FlowMovaLogo(width: 188),
        const SizedBox(height: 32),
        Text(
          'Trouvez une entreprise et suivez vos demandes.',
          style: textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Text(
          'L espace client sera le point d entree principal pour rechercher une entreprise, filtrer par domaine ou ville, puis creer ou consulter un ticket.',
          style: textTheme.titleMedium?.copyWith(color: FlowMovaColors.slate),
        ),
        const SizedBox(height: 28),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _BrandBadge(label: 'Recherche entreprises'),
            _BrandBadge(label: 'Filtres'),
            _BrandBadge(label: 'Suivi ticket'),
          ],
        ),
        const SizedBox(height: 28),
        _ClientActionCard(
          title: 'Rechercher une entreprise',
          description:
              'La recherche publique avec categorie, ville et pagination arrive dans PUBLIC-FRONT-001.',
          actionLabel: 'Voir le placeholder',
          icon: Icons.search_outlined,
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.companyDetail),
        ),
        const SizedBox(height: 12),
        _ClientActionCard(
          title: 'Consulter un ticket',
          description:
              'Acceder a un ticket avec son numero plateforme, puis suivre son statut.',
          actionLabel: 'Consulter',
          icon: Icons.confirmation_number_outlined,
          secondary: true,
          onPressed: () => Navigator.pushNamed(context, AppRoutes.ticketLookup),
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

class _ClientActionCard extends StatelessWidget {
  const _ClientActionCard({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.icon,
    required this.onPressed,
    this.secondary = false,
  });

  final String title;
  final String description;
  final String actionLabel;
  final IconData icon;
  final VoidCallback onPressed;
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
              ? OutlinedButton(onPressed: onPressed, child: Text(actionLabel))
              : FilledButton(onPressed: onPressed, child: Text(actionLabel));

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
