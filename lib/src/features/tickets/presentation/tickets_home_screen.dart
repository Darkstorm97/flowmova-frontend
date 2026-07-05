import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/theme/flow_mova_colors.dart';

class TicketsHomeScreen extends StatelessWidget {
  const TicketsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tickets',
          style: textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Text(
          'Retrouvez vos demandes connectees, les tickets recents de ce navigateur ou de cette application, ou consultez un ticket avec son code.',
          style: textTheme.titleMedium?.copyWith(color: FlowMovaColors.slate),
        ),
        const SizedBox(height: 28),
        _TicketShortcut(
          title: 'Mes tickets',
          subtitle:
              'Reserve aux tickets du compte connecte. La session sera branchee dans FRONT-012.',
          icon: Icons.person_search_outlined,
          routeName: AppRoutes.myTickets,
        ),
        const SizedBox(height: 12),
        _TicketShortcut(
          title: 'Recents sur cet appareil',
          subtitle:
              'Retrouver les tickets crees localement depuis ce navigateur ou cette application.',
          icon: Icons.history_outlined,
          routeName: AppRoutes.ticketLookup,
        ),
        const SizedBox(height: 12),
        _TicketShortcut(
          title: 'Voir un ticket avec le code',
          subtitle:
              'Consulter un ticket avec son numero et son code d acces, authentifie ou non.',
          icon: Icons.confirmation_number_outlined,
          routeName: AppRoutes.ticketLookup,
        ),
      ],
    );
  }
}

class _TicketShortcut extends StatelessWidget {
  const _TicketShortcut({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.routeName,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String routeName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: ListTile(
        leading: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: colorScheme.primary),
          ),
        ),
        title: Text(
          title,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.pushNamed(context, routeName),
      ),
    );
  }
}
