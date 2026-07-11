import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/session/session_scope.dart';
import '../../../core/theme/flow_mova_colors.dart';
import '../../tickets/data/current_user_ticket_gateway.dart';
import '../data/admin_service_units_gateway.dart';
import '../data/business_dashboard_gateway.dart';
import 'business_ticket_detail_screen.dart';

class BusinessTicketsScreen extends StatefulWidget {
  const BusinessTicketsScreen({
    super.key,
    required this.companyId,
    this.gateway,
  });

  final String companyId;
  final AdminServiceUnitsGateway? gateway;

  @override
  State<BusinessTicketsScreen> createState() => _BusinessTicketsScreenState();
}

class _BusinessTicketsScreenState extends State<BusinessTicketsScreen> {
  AdminServiceUnitsGateway? _gateway;
  Future<_CompanyTicketsBundle>? _future;
  _CompanyTicketsBundle? _bundle;
  final _ticketNumberController = TextEditingController();
  String? _status;
  String? _serviceUnitId;

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
        message: 'Connectez-vous pour suivre les tickets.',
      );
    }

    return FutureBuilder<_CompanyTicketsBundle>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _StateCard(
            icon: Icons.hourglass_empty,
            title: 'Chargement des tickets',
            message: 'Nous recuperons les demandes de l entreprise.',
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

        final bundle = _bundle ?? snapshot.requireData;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Suivi des tickets',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${bundle.tickets.totalItems} ticket${bundle.tickets.totalItems > 1 ? 's' : ''}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: FlowMovaColors.slate),
              ),
              const SizedBox(height: 16),
              _CompanyTicketFilters(
                ticketNumberController: _ticketNumberController,
                status: _status,
                serviceUnitId: _serviceUnitId,
                services: bundle.services.items,
                onStatusChanged: (value) => setState(() => _status = value),
                onServiceChanged: (value) =>
                    setState(() => _serviceUnitId = value),
                onApply: _reload,
              ),
              const SizedBox(height: 14),
              if (bundle.tickets.items.isEmpty)
                const _StateCard(
                  icon: Icons.confirmation_number_outlined,
                  title: 'Aucun ticket',
                  message:
                      'Aucun ticket ne correspond aux filtres selectionnes.',
                )
              else
                for (final ticket in bundle.tickets.items) ...[
                  _CompanyTicketCard(
                    ticket: ticket,
                    onOpen: () => _openTicket(ticket),
                    onReceive: ticket.status == 'CREATED'
                        ? () =>
                              _confirmStatus(ticket, 'RECEIVED', 'Marquer recu')
                        : null,
                    onTreat:
                        ticket.status == 'CREATED' ||
                            ticket.status == 'RECEIVED'
                        ? () => _confirmStatus(
                            ticket,
                            'TREATED',
                            'Marquer traite',
                          )
                        : null,
                    onClose: _canClose(ticket)
                        ? () => _confirmStatus(
                            ticket,
                            'CLOSED',
                            'Terminer',
                            irreversible: true,
                          )
                        : null,
                    onCancel:
                        ticket.status == 'CREATED' ||
                            ticket.status == 'RECEIVED'
                        ? () => _confirmStatus(
                            ticket,
                            'CANCELLED',
                            'Annuler',
                            irreversible: true,
                          )
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

  Future<_CompanyTicketsBundle> _load() async {
    final services = await _gateway!.listServiceUnits(
      widget.companyId,
      size: 100,
    );
    final tickets = await _gateway!.listCompanyTickets(
      widget.companyId,
      serviceUnitId: _serviceUnitId,
      status: _status,
      ticketNumber: _ticketNumberController.text,
    );
    final bundle = _CompanyTicketsBundle(services: services, tickets: tickets);
    _bundle = bundle;
    return bundle;
  }

  Future<void> _openTicket(CurrentUserTicket ticket) async {
    final updated = await Navigator.pushNamed(
      context,
      AppRoutes.businessTicketDetail,
      arguments: BusinessTicketDetailArguments(
        companyId: widget.companyId,
        ticket: ticket,
        gateway: _gateway!,
      ),
    );
    if (updated is CurrentUserTicket) {
      _applyTicketMutation(updated);
      unawaited(_refreshAfterMutation());
    }
  }

  void _applyTicketMutation(CurrentUserTicket updatedTicket) {
    final current = _bundle;
    if (current == null) {
      return;
    }
    final matchesFilters = _matchesCurrentFilters(updatedTicket);
    final existingItems = current.tickets.items
        .where((ticket) => ticket.id != updatedTicket.id)
        .toList(growable: true);
    if (matchesFilters) {
      existingItems.add(updatedTicket);
      existingItems.sort(
        (left, right) => left.createdAt.compareTo(right.createdAt),
      );
    }
    final totalItems = matchesFilters
        ? current.tickets.totalItems
        : (current.tickets.totalItems - 1).clamp(0, current.tickets.totalItems);
    final updatedBundle = _CompanyTicketsBundle(
      services: current.services,
      tickets: CurrentUserTicketPage(
        items: existingItems,
        page: current.tickets.page,
        size: current.tickets.size,
        totalItems: totalItems,
        totalPages: current.tickets.totalPages,
      ),
    );
    setState(() {
      _bundle = updatedBundle;
      _future = Future.value(updatedBundle);
    });
  }

  bool _matchesCurrentFilters(CurrentUserTicket ticket) {
    final serviceFilter = _serviceUnitId?.trim();
    if (serviceFilter != null &&
        serviceFilter.isNotEmpty &&
        ticket.serviceUnitId != serviceFilter) {
      return false;
    }
    final statusFilter = _status?.trim();
    if (statusFilter != null &&
        statusFilter.isNotEmpty &&
        ticket.status != statusFilter) {
      return false;
    }
    final ticketNumberFilter = _ticketNumberController.text
        .trim()
        .toLowerCase();
    if (ticketNumberFilter.isNotEmpty &&
        !ticket.ticketNumber.toLowerCase().contains(ticketNumberFilter)) {
      return false;
    }
    return true;
  }

  Future<void> _refreshAfterMutation() async {
    try {
      final bundle = await _load();
      if (!mounted) {
        return;
      }
      setState(() => _future = Future.value(bundle));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ticket mis a jour. Actualisez la liste pour resynchroniser.',
          ),
        ),
      );
    }
  }

  bool _canClose(CurrentUserTicket ticket) {
    return ticket.status == 'CREATED' ||
        ticket.status == 'RECEIVED' ||
        ticket.status == 'TREATED' ||
        ticket.status == 'CUSTOMER_CONFIRMED';
  }

  Future<void> _confirmStatus(
    CurrentUserTicket ticket,
    String status,
    String label, {
    bool irreversible = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$label ?'),
        content: Text(
          irreversible
              ? 'Ticket ${ticket.ticketNumber}. Cette action est definitive.'
              : 'Ticket ${ticket.ticketNumber}',
        ),
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
      final updated = await _gateway!.changeTicketStatus(
        widget.companyId,
        ticket.serviceUnitId,
        ticket.id,
        status,
      );
      if (mounted) {
        _applyTicketMutation(updated);
        unawaited(_refreshAfterMutation());
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

  void _reload() {
    setState(() => _future = _load());
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

class _CompanyTicketsBundle {
  const _CompanyTicketsBundle({required this.services, required this.tickets});

  final BusinessServiceUnitPage services;
  final CurrentUserTicketPage tickets;
}

class _CompanyTicketFilters extends StatelessWidget {
  const _CompanyTicketFilters({
    required this.ticketNumberController,
    required this.status,
    required this.serviceUnitId,
    required this.services,
    required this.onStatusChanged,
    required this.onServiceChanged,
    required this.onApply,
  });

  final TextEditingController ticketNumberController;
  final String? status;
  final String? serviceUnitId;
  final List<BusinessServiceUnit> services;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onServiceChanged;
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
              initialValue: serviceUnitId,
              decoration: const InputDecoration(labelText: 'Service'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Tous')),
                for (final service in services)
                  DropdownMenuItem(
                    value: service.id,
                    child: Text(service.name),
                  ),
              ],
              onChanged: onServiceChanged,
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
                DropdownMenuItem(
                  value: 'CUSTOMER_CONFIRMED',
                  child: Text('Confirme'),
                ),
                DropdownMenuItem(value: 'CLOSED', child: Text('Termine')),
                DropdownMenuItem(value: 'CANCELLED', child: Text('Annule')),
              ],
              onChanged: onStatusChanged,
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

class _CompanyTicketCard extends StatelessWidget {
  const _CompanyTicketCard({
    required this.ticket,
    required this.onOpen,
    required this.onReceive,
    required this.onTreat,
    required this.onClose,
    required this.onCancel,
  });

  final CurrentUserTicket ticket;
  final VoidCallback onOpen;
  final VoidCallback? onReceive;
  final VoidCallback? onTreat;
  final VoidCallback? onClose;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final customer = ticket.guestName?.trim().isNotEmpty == true
        ? ticket.guestName!.trim()
        : ticket.userId.isNotEmpty
        ? 'Client connecte'
        : (ticket.customerPhone ?? 'Invite');
    final subtitleParts = [
      ticket.serviceUnitName,
      if (!ticket.locationDefault && ticket.locationName.trim().isNotEmpty)
        ticket.locationName,
      ticket.totalLabel,
    ].where((part) => part.trim().isNotEmpty).join(' - ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
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
              Text(subtitleParts),
              const SizedBox(height: 4),
              Text(
                customer,
                style: const TextStyle(color: FlowMovaColors.slate),
              ),
              const SizedBox(height: 10),
              if (ticket.lines.isEmpty)
                const Text(
                  'Aucun article commande',
                  style: TextStyle(color: FlowMovaColors.slate),
                )
              else
                for (final line in ticket.lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: FlowMovaColors.cloud,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'x${line.quantity}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(line.itemName)),
                        Text(line.lineTotalAmount.toStringAsFixed(2)),
                      ],
                    ),
                  ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Detail'),
                  ),
                  if (onReceive != null)
                    FilledButton.tonalIcon(
                      onPressed: onReceive,
                      icon: const Icon(Icons.inbox_outlined),
                      label: const Text('Recu'),
                    ),
                  if (onTreat != null)
                    FilledButton.tonalIcon(
                      onPressed: onTreat,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Traite'),
                    ),
                  if (onClose != null)
                    FilledButton.icon(
                      onPressed: onClose,
                      icon: const Icon(Icons.done_all_outlined),
                      label: const Text('Terminer'),
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
    'CLOSED' => 'Termine',
    _ => status,
  };
}
