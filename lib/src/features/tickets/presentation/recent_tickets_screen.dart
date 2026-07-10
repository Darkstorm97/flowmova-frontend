import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/theme/flow_mova_colors.dart';
import '../../../core/theme/flow_mova_radii.dart';
import '../data/recent_ticket_storage.dart';
import 'ticket_lookup_screen.dart';

class RecentTicketsScreen extends StatefulWidget {
  const RecentTicketsScreen({super.key, this.recentTicketStorage});

  final RecentTicketStorage? recentTicketStorage;

  @override
  State<RecentTicketsScreen> createState() => _RecentTicketsScreenState();
}

class _RecentTicketsScreenState extends State<RecentTicketsScreen> {
  late final RecentTicketStorage _recentTicketStorage =
      widget.recentTicketStorage ?? InMemoryRecentTicketStorage();
  late Future<List<RecentTicketEntry>> _recentTicketsFuture;

  @override
  void initState() {
    super.initState();
    _recentTicketsFuture = _recentTicketStorage.load();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tickets recents',
            style: textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Retrouvez les 5 derniers tickets invites crees depuis ce navigateur ou cette application.',
            style: textTheme.titleMedium?.copyWith(color: FlowMovaColors.slate),
          ),
          const SizedBox(height: 24),
          _RecentTicketsList(recentTicketsFuture: _recentTicketsFuture),
        ],
      ),
    );
  }
}

class _RecentTicketsList extends StatelessWidget {
  const _RecentTicketsList({required this.recentTicketsFuture});

  final Future<List<RecentTicketEntry>> recentTicketsFuture;

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
                        'Derniers tickets invites',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Ces tickets non connectes sont conserves uniquement sur cet appareil.',
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
        onTap: ticket.accessCode == null
            ? null
            : () => Navigator.pushNamed(
                context,
                AppRoutes.ticketLookup,
                arguments: TicketLookupArguments(recentTicket: ticket),
              ),
      ),
    );
  }
}
