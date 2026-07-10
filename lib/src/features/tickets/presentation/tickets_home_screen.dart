import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/theme/flow_mova_colors.dart';
import '../data/recent_ticket_storage.dart';

class TicketsHomeScreen extends StatelessWidget {
  const TicketsHomeScreen({super.key, this.recentTicketStorage});

  final RecentTicketStorage? recentTicketStorage;

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
          'Retrouvez vos demandes connectees, ouvrez vos tickets recents, ou consultez un ticket avec son code.',
          style: textTheme.titleMedium?.copyWith(color: FlowMovaColors.slate),
        ),
        const SizedBox(height: 28),
        _TicketShortcut(
          title: 'Mes tickets',
          subtitle:
              'Retrouvez les tickets crees avec votre compte et suivez leur progression.',
          icon: Icons.person_search_outlined,
          routeName: AppRoutes.myTickets,
        ),
        const SizedBox(height: 12),
        const _TicketShortcut(
          title: 'Tickets recents',
          subtitle:
              'Voir les tickets conserves uniquement sur ce navigateur ou cette application.',
          icon: Icons.history_outlined,
          routeName: AppRoutes.recentTickets,
        ),
        const SizedBox(height: 12),
        const _TicketShortcut(
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
