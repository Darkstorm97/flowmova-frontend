import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/theme/flow_mova_colors.dart';
import '../../../core/theme/flow_mova_radii.dart';
import '../data/recent_ticket_storage.dart';
import 'ticket_lookup_screen.dart';

class TicketCreationSuccessScreen extends StatelessWidget {
  const TicketCreationSuccessScreen({super.key, required this.arguments});

  final TicketCreationSuccessArguments arguments;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 58,
                        color: FlowMovaColors.leafGreen,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Commande creee',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: FlowMovaColors.logoInk,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Conservez ces informations pour suivre votre commande.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: FlowMovaColors.slate,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _InfoTile(
                        icon: Icons.confirmation_number_outlined,
                        label: 'Numero',
                        value: arguments.ticketNumber,
                      ),
                      if (arguments.accessCode != null) ...[
                        const SizedBox(height: 10),
                        _AccessCodeCard(accessCode: arguments.accessCode!),
                      ],
                      const SizedBox(height: 10),
                      _InfoTile(
                        icon: Icons.business_outlined,
                        label: 'Entreprise',
                        value: arguments.companyName,
                      ),
                      const SizedBox(height: 10),
                      _InfoTile(
                        icon: Icons.room_service_outlined,
                        label: 'Service',
                        value: arguments.serviceUnitName,
                      ),
                      if (!arguments.locationDefault &&
                          arguments.locationName.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _InfoTile(
                          icon: Icons.place_outlined,
                          label: 'Emplacement',
                          value: arguments.locationName,
                        ),
                      ],
                      if (arguments.items.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Articles commandes',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        for (final item in arguments.items) ...[
                          _ItemRow(item: item),
                          const SizedBox(height: 8),
                        ],
                      ],
                      const SizedBox(height: 10),
                      _InfoTile(
                        icon: Icons.payments_outlined,
                        label: 'Total indicatif',
                        value: arguments.totalLabel,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => _openTicket(context),
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Voir le ticket'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.client,
                  (route) => false,
                ),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Retour accueil'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openTicket(BuildContext context) {
    final recentTicket = arguments.recentTicket;
    if (recentTicket?.accessCode != null) {
      Navigator.pushNamed(
        context,
        AppRoutes.ticketLookup,
        arguments: TicketLookupArguments(recentTicket: recentTicket),
      );
      return;
    }

    Navigator.pushNamed(context, AppRoutes.myTickets);
  }
}

class TicketCreationSuccessArguments {
  const TicketCreationSuccessArguments({
    required this.ticketId,
    required this.ticketNumber,
    required this.companyName,
    required this.serviceUnitName,
    required this.locationName,
    required this.totalLabel,
    this.locationDefault = false,
    this.accessCode,
    this.recentTicket,
    this.items = const [],
  });

  final String ticketId;
  final String ticketNumber;
  final String? accessCode;
  final String companyName;
  final String serviceUnitName;
  final String locationName;
  final bool locationDefault;
  final String totalLabel;
  final RecentTicketEntry? recentTicket;
  final List<TicketCreationSuccessItem> items;
}

class TicketCreationSuccessItem {
  const TicketCreationSuccessItem({
    required this.itemId,
    required this.name,
    required this.quantity,
  });

  final String itemId;
  final String name;
  final int quantity;
}

class _AccessCodeCard extends StatelessWidget {
  const _AccessCodeCard({required this.accessCode});

  final String accessCode;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FlowMovaColors.primaryAqua.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(FlowMovaRadii.medium),
        border: Border.all(
          color: FlowMovaColors.primaryAqua.withValues(alpha: 0.24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Code acces',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: FlowMovaColors.slate,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              accessCode,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: FlowMovaColors.logoInk,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ce code permet de retrouver ou confirmer votre commande.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: FlowMovaColors.slate),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FlowMovaColors.cloud,
        borderRadius: BorderRadius.circular(FlowMovaRadii.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: FlowMovaColors.slate),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: FlowMovaColors.slate,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: FlowMovaColors.logoInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final TicketCreationSuccessItem item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: FlowMovaColors.border),
        borderRadius: BorderRadius.circular(FlowMovaRadii.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: FlowMovaColors.primaryAqua.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(FlowMovaRadii.medium),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Text(
                  'x${item.quantity}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.name,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
