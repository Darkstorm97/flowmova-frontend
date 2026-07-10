import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/theme/flow_mova_colors.dart';

class BusinessHomeScreen extends StatelessWidget {
  const BusinessHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Espace entreprise',
          style: textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Text(
          'Retrouvez vos entreprises rattachees, puis ouvrez leur espace d administration.',
          style: textTheme.titleMedium?.copyWith(color: FlowMovaColors.slate),
        ),
        const SizedBox(height: 28),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Administration entreprise',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Commencez par selectionner une entreprise. Le dashboard complet sera branche progressivement avec les services, catalogues et tickets admin.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: FlowMovaColors.slate,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.myCompanies),
                      child: const Text('Mes entreprises'),
                    ),
                    OutlinedButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.businessDashboard,
                      ),
                      child: const Text('Dashboard'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
