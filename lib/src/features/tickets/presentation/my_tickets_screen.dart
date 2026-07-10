import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/session/auth_session_controller.dart';
import '../../../core/session/session_scope.dart';
import '../../../core/theme/flow_mova_colors.dart';
import '../../../core/theme/flow_mova_radii.dart';
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
    final canCancel = _canCancel(_ticket.status);
    final canConfirmTreatment = _ticket.status == 'TREATED';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ConnectedTicketDetailCard(
            ticket: _ticket,
            actionLoading: _isSubmitting,
            errorMessage: _actionError,
            onCancel: canCancel ? () => _cancel(context) : null,
            onConfirmTreatment: canConfirmTreatment
                ? () => _confirmTreatment(context)
                : null,
          ),
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
                      ticket.companyName.isEmpty
                          ? ticket.ticketNumber
                          : ticket.companyName,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _StatusChip(status: ticket.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                ticket.serviceUnitName.isEmpty
                    ? ticket.ticketNumber
                    : '${ticket.serviceUnitName} - ${ticket.ticketNumber}',
                style: textTheme.bodyMedium?.copyWith(
                  color: FlowMovaColors.slate,
                  fontWeight: FontWeight.w700,
                ),
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

class _ConnectedTicketDetailCard extends StatelessWidget {
  const _ConnectedTicketDetailCard({
    required this.ticket,
    required this.actionLoading,
    required this.errorMessage,
    required this.onCancel,
    required this.onConfirmTreatment,
  });

  final CurrentUserTicket ticket;
  final bool actionLoading;
  final String? errorMessage;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirmTreatment;

  @override
  Widget build(BuildContext context) {
    final createdAtLabel = _dateLabel(ticket.createdAt);
    final updatedAtLabel = ticket.updatedAt == null
        ? null
        : _dateLabel(ticket.updatedAt!);
    final showLocation =
        !ticket.locationDefault && ticket.locationName.trim().isNotEmpty;
    final contextLabel = _ticketContextLabel(
      companyName: _ticketCompanyName(ticket),
      serviceName: _ticketServiceName(ticket),
      locationName: showLocation ? _ticketLocationName(ticket) : null,
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: FlowMovaColors.primaryAqua.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(FlowMovaRadii.large),
                border: Border.all(
                  color: FlowMovaColors.primaryAqua.withValues(alpha: 0.2),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: FlowMovaColors.white,
                        borderRadius: BorderRadius.circular(
                          FlowMovaRadii.medium,
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.receipt_long_outlined),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.ticketNumber,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: FlowMovaColors.logoInk,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            contextLabel,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: FlowMovaColors.slate,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cree le $createdAtLabel',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: FlowMovaColors.slate),
                          ),
                        ],
                      ),
                    ),
                    _StatusChip(status: ticket.status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _ConnectedTicketProgress(status: ticket.status),
            const SizedBox(height: 16),
            _ConnectedTicketInfoGrid(
              items: [
                if (ticket.customerPhone != null &&
                    ticket.customerPhone!.trim().isNotEmpty)
                  _ConnectedTicketInfoItem(
                    icon: Icons.phone_outlined,
                    label: 'Telephone',
                    value: ticket.customerPhone!,
                  ),
                _ConnectedTicketInfoItem(
                  icon: Icons.payments_outlined,
                  label: 'Total',
                  value: ticket.totalLabel,
                ),
                if (updatedAtLabel != null)
                  _ConnectedTicketInfoItem(
                    icon: Icons.update_outlined,
                    label: 'Mis a jour',
                    value: updatedAtLabel,
                  ),
              ],
            ),
            if (ticket.notes != null && ticket.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              _ConnectedTicketNote(note: ticket.notes!),
            ],
            const SizedBox(height: 18),
            const _ConnectedSectionTitle(
              icon: Icons.shopping_bag_outlined,
              label: 'Articles commandes',
            ),
            const SizedBox(height: 8),
            if (ticket.lines.isEmpty)
              const _ConnectedEmptyLineItems()
            else
              for (final line in ticket.lines)
                _ConnectedTicketLineTile(line: line),
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              _InlineError(message: errorMessage!),
            ],
            const SizedBox(height: 16),
            _ConnectedTicketActions(
              actionLoading: actionLoading,
              onCancel: onCancel,
              onConfirmTreatment: onConfirmTreatment,
            ),
            const SizedBox(height: 12),
            const _ConnectedInfoMessage(
              icon: Icons.verified_user_outlined,
              text:
                  'Statut rafraichi depuis votre compte FlowMova. Les actions restent synchronisees avec le backend.',
              color: FlowMovaColors.primaryAqua,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectedTicketProgress extends StatelessWidget {
  const _ConnectedTicketProgress({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    const steps = ['CREATED', 'RECEIVED', 'TREATED', 'CUSTOMER_CONFIRMED'];
    final activeIndex = steps.indexOf(status);
    final isCancelled = status == 'CANCELLED';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: FlowMovaColors.cloud,
        borderRadius: BorderRadius.circular(FlowMovaRadii.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: isCancelled
            ? const Row(
                children: [
                  Icon(Icons.cancel_outlined, color: FlowMovaColors.error),
                  SizedBox(width: 8),
                  Expanded(child: Text('Ce ticket a ete annule.')),
                ],
              )
            : Row(
                children: [
                  for (var index = 0; index < steps.length; index++) ...[
                    Expanded(
                      child: _ConnectedProgressStep(
                        label: _statusLabel(steps[index]),
                        active: activeIndex >= index,
                      ),
                    ),
                    if (index != steps.length - 1)
                      Container(
                        width: 16,
                        height: 2,
                        color: activeIndex > index
                            ? FlowMovaColors.primaryAqua
                            : FlowMovaColors.border,
                      ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _ConnectedProgressStep extends StatelessWidget {
  const _ConnectedProgressStep({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          active ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18,
          color: active ? FlowMovaColors.primaryAqua : FlowMovaColors.slate,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: active ? FlowMovaColors.logoInk : FlowMovaColors.slate,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ConnectedTicketInfoGrid extends StatelessWidget {
  const _ConnectedTicketInfoGrid({required this.items});

  final List<_ConnectedTicketInfoItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final useColumns = constraints.maxWidth >= 520;
        final itemWidth = useColumns
            ? (constraints.maxWidth - 10) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final item in items) SizedBox(width: itemWidth, child: item),
          ],
        );
      },
    );
  }
}

class _ConnectedTicketInfoItem extends StatelessWidget {
  const _ConnectedTicketInfoItem({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: FlowMovaColors.slate),
            const SizedBox(width: 8),
            SizedBox(
              width: 76,
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: FlowMovaColors.slate,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                softWrap: true,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: FlowMovaColors.logoInk,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectedSectionTitle extends StatelessWidget {
  const _ConnectedSectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: FlowMovaColors.logoInk),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _ConnectedTicketNote extends StatelessWidget {
  const _ConnectedTicketNote({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FlowMovaColors.softApricot.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(FlowMovaRadii.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.notes_outlined, color: FlowMovaColors.logoInk),
            const SizedBox(width: 8),
            Expanded(child: Text(note)),
          ],
        ),
      ),
    );
  }
}

class _ConnectedEmptyLineItems extends StatelessWidget {
  const _ConnectedEmptyLineItems();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FlowMovaColors.cloud,
        borderRadius: BorderRadius.circular(FlowMovaRadii.medium),
      ),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Text('Aucun article associe a ce ticket.'),
      ),
    );
  }
}

class _ConnectedTicketLineTile extends StatelessWidget {
  const _ConnectedTicketLineTile({required this.line});

  final CurrentUserTicketLine line;

  @override
  Widget build(BuildContext context) {
    final name = line.itemName.trim().isEmpty
        ? 'Article ${_shortId(line.itemId)}'
        : line.itemName;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
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
                    vertical: 6,
                  ),
                  child: Text(
                    'x${line.quantity}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: FlowMovaColors.logoInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (line.notes != null && line.notes!.trim().isNotEmpty)
                      Text(
                        line.notes!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: FlowMovaColors.slate,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                line.lineTotalAmount.toStringAsFixed(2),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectedTicketActions extends StatelessWidget {
  const _ConnectedTicketActions({
    required this.actionLoading,
    required this.onCancel,
    required this.onConfirmTreatment,
  });

  final bool actionLoading;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirmTreatment;

  @override
  Widget build(BuildContext context) {
    if (onCancel == null && onConfirmTreatment == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ConnectedSectionTitle(
          icon: Icons.touch_app_outlined,
          label: 'Actions',
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (onCancel != null)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: FlowMovaColors.error,
                  side: BorderSide(
                    color: FlowMovaColors.error.withValues(alpha: 0.45),
                  ),
                  backgroundColor: FlowMovaColors.error.withValues(alpha: 0.06),
                ),
                onPressed: actionLoading ? null : onCancel,
                icon: actionLoading
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cancel_outlined),
                label: const Text('Annuler'),
              ),
            if (onConfirmTreatment != null)
              FilledButton.icon(
                onPressed: actionLoading ? null : onConfirmTreatment,
                icon: actionLoading
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.verified_outlined),
                label: const Text('Confirmer le traitement'),
              ),
          ],
        ),
      ],
    );
  }
}

class _ConnectedInfoMessage extends StatelessWidget {
  const _ConnectedInfoMessage({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(FlowMovaRadii.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}

String _dateLabel(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
}

String _ticketContextLabel({
  required String companyName,
  required String serviceName,
  required String? locationName,
}) {
  final parts = [companyName, serviceName, locationName]
      .where((part) => part != null && part.trim().isNotEmpty)
      .cast<String>()
      .toList(growable: false);
  return parts.join(' - ');
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

String _ticketCompanyName(CurrentUserTicket ticket) {
  return ticket.companyName.trim().isEmpty
      ? _shortId(ticket.companyId)
      : ticket.companyName;
}

String _ticketServiceName(CurrentUserTicket ticket) {
  return ticket.serviceUnitName.trim().isEmpty
      ? _shortId(ticket.serviceUnitId)
      : ticket.serviceUnitName;
}

String _ticketLocationName(CurrentUserTicket ticket) {
  return ticket.locationName.trim().isEmpty
      ? _shortId(ticket.locationId)
      : ticket.locationName;
}
