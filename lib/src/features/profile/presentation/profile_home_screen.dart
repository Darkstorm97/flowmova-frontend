import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/theme/flow_mova_colors.dart';

class ProfileHomeScreen extends StatelessWidget {
  const ProfileHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profil',
          style: textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Text(
          'Connectez-vous pour retrouver vos tickets, vos entreprises et vos informations de compte.',
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
                  'Vous n etes pas connecte',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'La session et le profil seront branches dans les issues AUTH-FRONT.',
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
                          Navigator.pushNamed(context, AppRoutes.login),
                      child: const Text('Se connecter'),
                    ),
                    OutlinedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.register),
                      child: const Text('Creer un compte'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ProfileShortcut(
          title: 'Mes infos profil',
          subtitle: 'Acces futur aux informations du compte connecte.',
          routeName: AppRoutes.login,
        ),
      ],
    );
  }
}

class _ProfileShortcut extends StatelessWidget {
  const _ProfileShortcut({
    required this.title,
    required this.subtitle,
    required this.routeName,
  });

  final String title;
  final String subtitle;
  final String routeName;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.pushNamed(context, routeName),
      ),
    );
  }
}
