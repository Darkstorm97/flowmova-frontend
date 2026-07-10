import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/session/session_scope.dart';
import '../../../core/theme/flow_mova_colors.dart';
import '../../tickets/data/current_user_ticket_gateway.dart';
import '../data/admin_service_units_gateway.dart';
import '../data/business_dashboard_gateway.dart';

class BusinessServiceUnitTicketsArguments {
  const BusinessServiceUnitTicketsArguments({
    required this.companyId,
    required this.serviceUnit,
  });

  final String companyId;
  final BusinessServiceUnit serviceUnit;
}

class BusinessServiceUnitTicketsScreen extends StatefulWidget {
  const BusinessServiceUnitTicketsScreen({
    super.key,
    required this.companyId,
    required this.serviceUnit,
    this.gateway,
  });

  final String companyId;
  final BusinessServiceUnit serviceUnit;
  final AdminServiceUnitsGateway? gateway;

  @override
  State<BusinessServiceUnitTicketsScreen> createState() =>
      _BusinessServiceUnitTicketsScreenState();
}

class _BusinessServiceUnitTicketsScreenState
    extends State<BusinessServiceUnitTicketsScreen> {
  AdminServiceUnitsGateway? _gateway;
  Future<_TicketAdminBundle>? _future;
  final _ticketNumberController = TextEditingController();
  String? _status;
  String? _locationId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.of(context);
    _gateway ??=
        widget.gateway ??
        BackendAdminServiceUnitsGateway(
          ApiClient(accessTokenProvider: session.currentAccessToken),
        );
    _future ??= _load();
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    if (!session.isAuthenticated) {
      return const _StateCard(
        icon: Icons.lock_outline,
        title: 'Connexion requise',
        message: 'Connectez-vous pour suivre les tickets de ce service.',
      );
    }

    return FutureBuilder<_TicketAdminBundle>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _StateCard(
            icon: Icons.hourglass_empty,
            title: 'Chargement des tickets',
            message: 'Nous recuperons les demandes du service.',
          );
        }
        if (snapshot.hasError) {
          return _StateCard(
            icon: Icons.error_outline,
            title: 'Tickets indisponibles',
            message: _errorMessage(snapshot.error),
            actionLabel: 'Reessayer',
            onAction: _reload,
          );
        }

        final bundle = snapshot.requireData;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.serviceUnit.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${bundle.page.totalItems} ticket${bundle.page.totalItems > 1 ? 's' : ''}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: FlowMovaColors.slate),
              ),
              const SizedBox(height: 16),
              _TicketFilters(
                ticketNumberController: _ticketNumberController,
                status: _status,
                locationId: _locationId,
                locations: bundle.locations.items,
                onStatusChanged: (value) => setState(() => _status = value),
                onLocationChanged: (value) =>
                    setState(() => _locationId = value),
                onApply: _reload,
              ),
              const SizedBox(height: 14),
              if (bundle.page.items.isEmpty)
                const _StateCard(
                  icon: Icons.confirmation_number_outlined,
                  title: 'Aucun ticket',
                  message:
                      'Ce service n a pas encore de ticket pour ce filtre.',
                )
              else
                for (final ticket in bundle.page.items) ...[
                  _AdminTicketCard(
                    ticket: ticket,
                    onReceive: _canReceive(ticket)
                        ? () =>
                              _confirmStatus(ticket, 'RECEIVED', 'Marquer recu')
                        : null,
                    onTreat: _canTreat(ticket)
                        ? () => _confirmStatus(
                            ticket,
                            'TREATED',
                            'Marquer traite',
                          )
                        : null,
                    onCancel: _canCancel(ticket)
                        ? () => _confirmStatus(ticket, 'CANCELLED', 'Annuler')
                        : null,
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        );
      },
    );
  }

  Future<_TicketAdminBundle> _load() async {
    final gateway = _gateway!;
    final tickets = await gateway.listTickets(
      widget.companyId,
      widget.serviceUnit.id,
      status: _status,
      ticketNumber: _ticketNumberController.text,
      locationId: _locationId,
    );
    final locations = await gateway.listLocations(
      widget.companyId,
      widget.serviceUnit.id,
      size: 100,
    );
    return _TicketAdminBundle(page: tickets, locations: locations);
  }

  void _reload() {
    setState(() => _future = _load());
  }

  bool _canReceive(CurrentUserTicket ticket) => ticket.status == 'CREATED';

  bool _canTreat(CurrentUserTicket ticket) => ticket.status == 'RECEIVED';

  bool _canCancel(CurrentUserTicket ticket) =>
      ticket.status == 'CREATED' || ticket.status == 'RECEIVED';

  Future<void> _confirmStatus(
    CurrentUserTicket ticket,
    String status,
    String label,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$label ?'),
        content: Text('Ticket ${ticket.ticketNumber}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Fermer'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(label),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    try {
      await _gateway!.changeTicketStatus(
        widget.companyId,
        widget.serviceUnit.id,
        ticket.id,
        status,
      );
      if (mounted) {
        _reload();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    }
  }

  String _errorMessage(Object? error) {
    if (error is ApiException) {
      return error.message;
    }
    if (error is FormatException) {
      return 'Les donnees tickets sont illisibles.';
    }
    return 'Impossible de charger les tickets pour le moment.';
  }

  @override
  void dispose() {
    _ticketNumberController.dispose();
    super.dispose();
  }
}

class _TicketAdminBundle {
  const _TicketAdminBundle({required this.page, required this.locations});

  final CurrentUserTicketPage page;
  final BusinessServiceUnitLocationPage locations;
}

class _TicketFilters extends StatelessWidget {
  const _TicketFilters({
    required this.ticketNumberController,
    required this.status,
    required this.locationId,
    required this.locations,
    required this.onStatusChanged,
    required this.onLocationChanged,
    required this.onApply,
  });

  final TextEditingController ticketNumberController;
  final String? status;
  final String? locationId;
  final List<BusinessServiceUnitLocation> locations;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onLocationChanged;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: ticketNumberController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Numero ticket',
              ),
              onSubmitted: (_) => onApply(),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String?>(
              initialValue: status,
              decoration: const InputDecoration(labelText: 'Statut'),
              items: const [
                DropdownMenuItem(value: null, child: Text('Tous')),
                DropdownMenuItem(value: 'CREATED', child: Text('Cree')),
                DropdownMenuItem(value: 'RECEIVED', child: Text('Recu')),
                DropdownMenuItem(value: 'TREATED', child: Text('Traite')),
                DropdownMenuItem(value: 'CANCELLED', child: Text('Annule')),
                DropdownMenuItem(
                  value: 'CUSTOMER_CONFIRMED',
                  child: Text('Confirme'),
                ),
              ],
              onChanged: onStatusChanged,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String?>(
              initialValue: locationId,
              decoration: const InputDecoration(labelText: 'Emplacement'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Tous')),
                for (final location in locations)
                  DropdownMenuItem(
                    value: location.id,
                    child: Text(location.name),
                  ),
              ],
              onChanged: onLocationChanged,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onApply,
                icon: const Icon(Icons.filter_alt_outlined),
                label: const Text('Appliquer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminTicketCard extends StatelessWidget {
  const _AdminTicketCard({
    required this.ticket,
    required this.onReceive,
    required this.onTreat,
    required this.onCancel,
  });

  final CurrentUserTicket ticket;
  final VoidCallback? onReceive;
  final VoidCallback? onTreat;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final customer = ticket.userId.isNotEmpty
        ? 'Client connecte'
        : (ticket.customerPhone ?? 'Invite');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ticket.ticketNumber,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _StatusPill(label: _ticketStatusLabel(ticket.status)),
              ],
            ),
            const SizedBox(height: 8),
            Text('${ticket.locationName} - ${ticket.totalLabel}'),
            const SizedBox(height: 4),
            Text(customer, style: const TextStyle(color: FlowMovaColors.slate)),
            if (ticket.lines.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                ticket.lines.map((line) => line.itemName).join(', '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onReceive != null)
                  FilledButton.tonalIcon(
                    onPressed: onReceive,
                    icon: const Icon(Icons.inbox_outlined),
                    label: const Text('Recu'),
                  ),
                if (onTreat != null)
                  FilledButton.icon(
                    onPressed: onTreat,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Traite'),
                  ),
                if (onCancel != null)
                  OutlinedButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Annuler'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FlowMovaColors.primaryAqua.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: FlowMovaColors.primaryAqua),
            const SizedBox(height: 10),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(message),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

String _ticketStatusLabel(String status) {
  return switch (status) {
    'CREATED' => 'Cree',
    'RECEIVED' => 'Recu',
    'TREATED' => 'Traite',
    'CUSTOMER_CONFIRMED' => 'Confirme',
    'CANCELLED' => 'Annule',
    'CLOSED' => 'Ferme',
    _ => status,
  };
}
