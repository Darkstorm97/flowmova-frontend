import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/session/auth_session_controller.dart';
import '../../../core/session/session_scope.dart';
import '../../../core/theme/flow_mova_colors.dart';
import '../data/current_user_ticket_gateway.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({this.gateway, super.key});

  final CurrentUserTicketGateway? gateway;

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  CurrentUserTicketGateway? _gateway;
  Future<CurrentUserTicketPage>? _ticketsFuture;
  AuthSessionController? _sessionController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final sessionController = SessionScope.of(context);
    if (_sessionController != sessionController) {
      _sessionController?.removeListener(_handleSessionChanged);
      _sessionController = sessionController;
      _sessionController!.addListener(_handleSessionChanged);
    }

    _gateway ??=
        widget.gateway ??
        BackendCurrentUserTicketGateway(
          ApiClient(accessTokenProvider: sessionController.currentAccessToken),
        );

    if (sessionController.isAuthenticated && _ticketsFuture == null) {
      _ticketsFuture = _gateway!.listTickets();
    }
  }

  void _handleSessionChanged() {
    final session = _sessionController;
    if (session == null || !mounted) {
      return;
    }

    setState(() {
      _ticketsFuture = session.isAuthenticated ? _gateway!.listTickets() : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final session = SessionScope.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mes tickets',
          style: textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Text(
          'Suivez les tickets crees avec votre compte FlowMova.',
          style: textTheme.titleMedium?.copyWith(color: FlowMovaColors.slate),
        ),
        const SizedBox(height: 24),
        if (session.status == AuthSessionStatus.unknown)
          const _MyTicketsLoadingCard()
        else if (!session.isAuthenticated)
          _SignedOutTicketsCard(
            isExpired: session.status == AuthSessionStatus.expired,
          )
        else
          FutureBuilder<CurrentUserTicketPage>(
            future: _ticketsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const _MyTicketsLoadingCard();
              }

              if (snapshot.hasError) {
                return _MyTicketsErrorCard(
                  message: _errorMessage(snapshot.error),
                  onRetry: _reload,
                );
              }

              final page = snapshot.requireData;
              if (page.items.isEmpty) {
                return const _EmptyTicketsCard();
              }

              return _MyTicketsList(
                page: page,
                onRefresh: _reload,
                onOpenTicket: _openTicket,
              );
            },
          ),
      ],
    );
  }

  Future<void> _openTicket(CurrentUserTicket ticket) async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.myTicketDetail,
      arguments: MyTicketDetailArguments(ticket: ticket, gateway: _gateway!),
    );

    if (result is CurrentUserTicket) {
      _replaceTicket(result);
    }
  }

  void _replaceTicket(CurrentUserTicket updatedTicket) {
    final currentFuture = _ticketsFuture;
    if (currentFuture == null) {
      return;
    }

    setState(() {
      _ticketsFuture = currentFuture.then((page) {
        return CurrentUserTicketPage(
          items: page.items
              .map(
                (ticket) =>
                    ticket.id == updatedTicket.id ? updatedTicket : ticket,
              )
              .toList(growable: false),
          page: page.page,
          size: page.size,
          totalItems: page.totalItems,
          totalPages: page.totalPages,
        );
      });
    });
  }

  void _reload() {
    setState(() {
      _ticketsFuture = _gateway!.listTickets();
    });
  }

  String _errorMessage(Object? error) {
    if (error is ApiException) {
      return error.message;
    }
    return 'Impossible de charger vos tickets pour le moment.';
  }

  @override
  void dispose() {
    _sessionController?.removeListener(_handleSessionChanged);
    super.dispose();
  }
}

class MyTicketDetailArguments {
  const MyTicketDetailArguments({required this.ticket, required this.gateway});

  final CurrentUserTicket ticket;
  final CurrentUserTicketGateway gateway;
}

class MyTicketDetailScreen extends StatefulWidget {
  const MyTicketDetailScreen({
    required this.ticket,
    required this.gateway,
    super.key,
  });

  final CurrentUserTicket ticket;
  final CurrentUserTicketGateway gateway;

  @override
  State<MyTicketDetailScreen> createState() => _MyTicketDetailScreenState();
}

class _MyTicketDetailScreenState extends State<MyTicketDetailScreen> {
  late CurrentUserTicket _ticket = widget.ticket;
  bool _isSubmitting = false;
  String? _actionError;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final canCancel = _canCancel(_ticket.status);
    final canConfirmTreatment = _ticket.status == 'TREATED';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, _ticket),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Retour'),
          ),
          const SizedBox(height: 8),
          _TicketSummaryCard(ticket: _ticket),
          const SizedBox(height: 16),
          Text(
            'Details',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          _TicketDetailInfo(ticket: _ticket),
          if (_ticket.lines.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Articles',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            for (final line in _ticket.lines) _TicketLineCard(line: line),
          ],
          if (_actionError != null) ...[
            const SizedBox(height: 16),
            _InlineError(message: _actionError!),
          ],
          if (canCancel || canConfirmTreatment) ...[
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (canConfirmTreatment)
                  FilledButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () => _confirmTreatment(context),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Confirmer le traitement'),
                  ),
                if (canCancel)
                  OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : () => _cancel(context),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Annuler'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: FlowMovaColors.error,
                      side: const BorderSide(color: FlowMovaColors.error),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _cancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler ce ticket ?'),
        content: Text(
          'Le ticket ${_ticket.ticketNumber} sera annule. Cette action ne pourra pas etre annulee.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Retour'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: FlowMovaColors.error,
            ),
            child: const Text('Annuler definitivement'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await _runAction(() => widget.gateway.cancelTicket(_ticket.id));
  }

  Future<void> _confirmTreatment(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer le traitement ?'),
        content: Text(
          'Confirmez que le ticket ${_ticket.ticketNumber} a bien ete traite.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Retour'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await _runAction(() => widget.gateway.confirmTicketTreatment(_ticket.id));
  }

  Future<void> _runAction(Future<CurrentUserTicket> Function() action) async {
    setState(() {
      _isSubmitting = true;
      _actionError = null;
    });

    try {
      final updatedTicket = await action();
      if (!mounted) {
        return;
      }
      setState(() => _ticket = updatedTicket);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _actionError = error.message);
      }
    } on Object {
      if (mounted) {
        setState(() => _actionError = 'Action impossible pour le moment.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  bool _canCancel(String status) => status == 'CREATED' || status == 'RECEIVED';
}

class _MyTicketsList extends StatelessWidget {
  const _MyTicketsList({
    required this.page,
    required this.onRefresh,
    required this.onOpenTicket,
  });

  final CurrentUserTicketPage page;
  final VoidCallback onRefresh;
  final ValueChanged<CurrentUserTicket> onOpenTicket;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${page.totalItems} ticket${page.totalItems > 1 ? 's' : ''}',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Rafraichir',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final ticket in page.items) ...[
          _MyTicketListCard(ticket: ticket, onTap: () => onOpenTicket(ticket)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _MyTicketListCard extends StatelessWidget {
  const _MyTicketListCard({required this.ticket, required this.onTap});

  final CurrentUserTicket ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      ticket.ticketNumber,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _StatusChip(status: ticket.status),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaPill(
                    icon: Icons.calendar_today_outlined,
                    label: _formatDate(ticket.createdAt),
                  ),
                  _MetaPill(
                    icon: Icons.receipt_long_outlined,
                    label: ticket.totalLabel,
                  ),
                  if (ticket.lines.isNotEmpty)
                    _MetaPill(
                      icon: Icons.shopping_bag_outlined,
                      label:
                          '${ticket.lines.length} article${ticket.lines.length > 1 ? 's' : ''}',
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _statusMessage(ticket.status),
                      style: textTheme.bodyMedium?.copyWith(
                        color: FlowMovaColors.slate,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketSummaryCard extends StatelessWidget {
  const _TicketSummaryCard({required this.ticket});

  final CurrentUserTicket ticket;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    ticket.ticketNumber,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: FlowMovaColors.logoInk,
                    ),
                  ),
                ),
                _StatusChip(status: ticket.status),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _statusMessage(ticket.status),
              style: textTheme.bodyLarge?.copyWith(color: FlowMovaColors.slate),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaPill(
                  icon: Icons.calendar_today_outlined,
                  label: 'Cree le ${_formatDate(ticket.createdAt)}',
                ),
                _MetaPill(
                  icon: Icons.receipt_long_outlined,
                  label: ticket.totalLabel,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketDetailInfo extends StatelessWidget {
  const _TicketDetailInfo({required this.ticket});

  final CurrentUserTicket ticket;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _InfoRow(label: 'Service', value: _shortId(ticket.serviceUnitId)),
            _InfoRow(label: 'Emplacement', value: _shortId(ticket.locationId)),
            if (ticket.customerPhone != null &&
                ticket.customerPhone!.trim().isNotEmpty)
              _InfoRow(label: 'Telephone', value: ticket.customerPhone!),
            if (ticket.notes != null && ticket.notes!.trim().isNotEmpty)
              _InfoRow(label: 'Notes', value: ticket.notes!),
            if (ticket.updatedAt != null)
              _InfoRow(
                label: 'Mis a jour',
                value: _formatDate(ticket.updatedAt!),
              ),
          ],
        ),
      ),
    );
  }
}

class _TicketLineCard extends StatelessWidget {
  const _TicketLineCard({required this.line});

  final CurrentUserTicketLine line;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: FlowMovaColors.cloud,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.shopping_bag_outlined),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Article ${_shortId(line.itemId)}',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Quantite ${line.quantity} - ${line.lineTotalAmount.toStringAsFixed(2)}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: FlowMovaColors.slate,
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

class _SignedOutTicketsCard extends StatelessWidget {
  const _SignedOutTicketsCard({required this.isExpired});

  final bool isExpired;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isExpired ? 'Session expiree' : 'Connectez-vous',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isExpired
                  ? 'Reconnectez-vous pour retrouver vos tickets.'
                  : 'Vos tickets de compte apparaissent ici une fois connecte.',
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
    );
  }
}

class _EmptyTicketsCard extends StatelessWidget {
  const _EmptyTicketsCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.confirmation_number_outlined),
            const SizedBox(height: 12),
            Text(
              'Aucun ticket connecte',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Les commandes creees avec votre compte apparaitront ici.',
              style: textTheme.bodyMedium?.copyWith(
                color: FlowMovaColors.slate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyTicketsLoadingCard extends StatelessWidget {
  const _MyTicketsLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Chargement des tickets...'),
          ],
        ),
      ),
    );
  }
}

class _MyTicketsErrorCard extends StatelessWidget {
  const _MyTicketsErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tickets indisponibles',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: FlowMovaColors.error,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'CREATED' => FlowMovaColors.skyBlue,
      'RECEIVED' => FlowMovaColors.primaryAqua,
      'TREATED' => FlowMovaColors.softApricot,
      'CUSTOMER_CONFIRMED' || 'CLOSED' => FlowMovaColors.leafGreen,
      'CANCELLED' => FlowMovaColors.error,
      _ => FlowMovaColors.slate,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          _statusLabel(status),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FlowMovaColors.cloud,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: FlowMovaColors.slate),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: textTheme.labelMedium?.copyWith(
                color: FlowMovaColors.slate,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(child: Text(value, style: textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FlowMovaColors.error.withValues(alpha: 0.08),
        border: Border.all(color: FlowMovaColors.error.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: FlowMovaColors.error),
        ),
      ),
    );
  }
}

String _statusLabel(String status) {
  return switch (status) {
    'CREATED' => 'Cree',
    'RECEIVED' => 'Recu',
    'TREATED' => 'Traite',
    'CUSTOMER_CONFIRMED' => 'Confirme',
    'CLOSED' => 'Ferme',
    'CANCELLED' => 'Annule',
    _ => status,
  };
}

String _statusMessage(String status) {
  return switch (status) {
    'CREATED' => 'Votre commande est creee et attend la prise en charge.',
    'RECEIVED' => 'Votre commande est prise en charge.',
    'TREATED' => 'Votre commande est traitee. Vous pouvez confirmer.',
    'CUSTOMER_CONFIRMED' => 'Traitement confirme par le client.',
    'CLOSED' => 'Ticket ferme.',
    'CANCELLED' => 'Ticket annule.',
    _ => 'Statut $status',
  };
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute';
}

String _shortId(String value) {
  if (value.length <= 8) {
    return value;
  }
  return value.substring(0, 8);
}
