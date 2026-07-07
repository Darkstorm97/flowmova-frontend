import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/theme/flow_mova_colors.dart';
import '../../../core/theme/flow_mova_radii.dart';
import '../data/recent_ticket_storage.dart';

class TicketsHomeScreen extends StatefulWidget {
  const TicketsHomeScreen({super.key, this.recentTicketStorage});

  final RecentTicketStorage? recentTicketStorage;

  @override
  State<TicketsHomeScreen> createState() => _TicketsHomeScreenState();
}

class _TicketsHomeScreenState extends State<TicketsHomeScreen> {
  late final RecentTicketStorage _recentTicketStorage =
      widget.recentTicketStorage ?? InMemoryRecentTicketStorage();
  late Future<List<RecentTicketEntry>> _recentTicketsFuture;

  @override
  void initState() {
    super.initState();
    _recentTicketsFuture = _recentTicketStorage.load();
  }

  void _reloadRecentTickets() {
    setState(() {
      _recentTicketsFuture = _recentTicketStorage.load();
    });
  }

  Future<void> _clearRecentTickets() async {
    await _recentTicketStorage.clear();
    _reloadRecentTickets();
  }

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
        _RecentTicketsSection(
          recentTicketsFuture: _recentTicketsFuture,
          onClear: _clearRecentTickets,
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

class _RecentTicketsSection extends StatelessWidget {
  const _RecentTicketsSection({
    required this.recentTicketsFuture,
    required this.onClear,
  });

  final Future<List<RecentTicketEntry>> recentTicketsFuture;
  final Future<void> Function() onClear;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RecentTicketEntry>>(
      future: recentTicketsFuture,
      builder: (context, snapshot) {
        final tickets = snapshot.data ?? const <RecentTicketEntry>[];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history_outlined),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Recents sur cet appareil',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (tickets.isNotEmpty)
                      TextButton(
                        onPressed: onClear,
                        child: const Text('Vider'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Ces tickets sont conserves uniquement dans ce navigateur ou cette application.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: FlowMovaColors.slate),
                ),
                const SizedBox(height: 12),
                if (snapshot.connectionState != ConnectionState.done)
                  const Center(child: CircularProgressIndicator())
                else if (tickets.isEmpty)
                  const _EmptyRecentTickets()
                else
                  Column(
                    children: [
                      for (final ticket in tickets) ...[
                        _RecentTicketTile(ticket: ticket),
                        if (ticket != tickets.last) const SizedBox(height: 10),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyRecentTickets extends StatelessWidget {
  const _EmptyRecentTickets();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FlowMovaColors.cloud,
        borderRadius: BorderRadius.circular(FlowMovaRadii.medium),
      ),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Text('Aucun ticket recent sur cet appareil pour le moment.'),
      ),
    );
  }
}

class _RecentTicketTile extends StatelessWidget {
  const _RecentTicketTile({required this.ticket});

  final RecentTicketEntry ticket;

  @override
  Widget build(BuildContext context) {
    final itemLabel = ticket.items.isEmpty
        ? 'Aucun article'
        : ticket.items
              .map((item) => '${item.name} x${item.quantity}')
              .join(', ');

    return Material(
      color: FlowMovaColors.cloud,
      borderRadius: BorderRadius.circular(FlowMovaRadii.medium),
      child: ListTile(
        leading: const Icon(Icons.confirmation_number_outlined),
        title: Text(ticket.ticketNumber),
        subtitle: Text(
          '${ticket.companyName} - ${ticket.serviceUnitName} - ${ticket.locationName}\n$itemLabel',
        ),
        isThreeLine: true,
        trailing: Text(
          ticket.status,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        onTap: () => Navigator.pushNamed(context, AppRoutes.ticketLookup),
      ),
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
