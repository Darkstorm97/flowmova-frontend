import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/theme/flow_mova_colors.dart';
import '../../../core/theme/flow_mova_radii.dart';
import '../data/recent_ticket_storage.dart';
import '../data/ticket_lookup_gateway.dart';

class TicketLookupArguments {
  const TicketLookupArguments({this.recentTicket});

  final RecentTicketEntry? recentTicket;
}

class TicketLookupScreen extends StatefulWidget {
  const TicketLookupScreen({
    super.key,
    this.arguments,
    this.lookupGateway,
    this.recentTicketStorage,
  });

  final TicketLookupArguments? arguments;
  final TicketLookupGateway? lookupGateway;
  final RecentTicketStorage? recentTicketStorage;

  @override
  State<TicketLookupScreen> createState() => _TicketLookupScreenState();
}

class _TicketLookupScreenState extends State<TicketLookupScreen> {
  late final TicketLookupGateway _lookupGateway =
      widget.lookupGateway ?? BackendTicketLookupGateway(ApiClient());
  late final RecentTicketStorage _recentTicketStorage =
      widget.recentTicketStorage ?? InMemoryRecentTicketStorage();
  late final TextEditingController _ticketNumberController =
      TextEditingController(
        text: widget.arguments?.recentTicket?.ticketNumber ?? '',
      );
  late final TextEditingController _accessCodeController =
      TextEditingController(
        text: widget.arguments?.recentTicket?.accessCode ?? '',
      );

  final _formKey = GlobalKey<FormState>();

  PublicTicket? _ticket;
  RecentTicketEntry? _recentTicket;
  bool _isLoading = false;
  bool _isActionLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _recentTicket = widget.arguments?.recentTicket;
    if (_recentTicket?.accessCode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _lookup());
    }
  }

  @override
  void dispose() {
    _ticketNumberController.dispose();
    _accessCodeController.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final ticket = await _lookupGateway.getGuestTicket(
        ticketNumber: _ticketNumberController.text,
        accessCode: _accessCodeController.text,
      );
      await _refreshRecentTicket(ticket);

      if (!mounted) {
        return;
      }

      setState(() {
        _ticket = ticket;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = _lookupErrorMessage(error);
      });
    }
  }

  Future<void> _refreshRecentTicket(PublicTicket ticket) async {
    final recent = _recentTicket;
    if (recent == null) {
      return;
    }

    final refreshed = recent.copyWith(
      status: ticket.status,
      totalLabel: ticket.totalLabel,
      guestName: ticket.guestName,
      customerPhone: ticket.customerPhone,
    );

    await _recentTicketStorage.save(refreshed);
    _recentTicket = refreshed;
  }

  Future<void> _runTicketAction(
    Future<PublicTicket> Function({
      required String ticketNumber,
      required String accessCode,
    })
    action, {
    required String successMessage,
  }) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isActionLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final ticket = await action(
        ticketNumber: _ticketNumberController.text,
        accessCode: _accessCodeController.text,
      );
      await _refreshRecentTicket(ticket);

      if (!mounted) {
        return;
      }

      setState(() {
        _ticket = ticket;
        _isActionLoading = false;
        _successMessage = successMessage;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isActionLoading = false;
        _errorMessage = _lookupErrorMessage(error);
      });
    }
  }

  Future<void> _cancelTicket() {
    return _runTicketAction(
      _lookupGateway.cancelGuestTicket,
      successMessage: 'Le ticket a ete annule.',
    );
  }

  Future<void> _confirmTreatment() {
    return _runTicketAction(
      _lookupGateway.confirmGuestTicketTreatment,
      successMessage: 'Le traitement du ticket a ete confirme.',
    );
  }

  String _lookupErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    if (error is FormatException) {
      return 'La reponse du ticket est illisible.';
    }
    return 'Impossible de retrouver ce ticket.';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Consulter un ticket',
            style: textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Entrez le numero et le code d acces, ou ouvrez un ticket recent conserve sur cet appareil.',
            style: textTheme.titleMedium?.copyWith(color: FlowMovaColors.slate),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _ticketNumberController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Numero de ticket',
                        prefixIcon: Icon(Icons.confirmation_number_outlined),
                      ),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _accessCodeController,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Code d acces',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: _requiredValidator,
                      onFieldSubmitted: (_) => _lookup(),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      _LookupMessage(
                        icon: Icons.error_outline,
                        text: _errorMessage!,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ],
                    if (_successMessage != null) ...[
                      const SizedBox(height: 12),
                      _LookupMessage(
                        icon: Icons.check_circle_outline,
                        text: _successMessage!,
                        color: FlowMovaColors.leafGreen,
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _isLoading || _isActionLoading
                          ? null
                          : _lookup,
                      icon: _isLoading
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_outlined),
                      label: Text(
                        _isLoading
                            ? 'Rafraichissement...'
                            : 'Rafraichir le ticket',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_ticket != null)
            _TicketSummary(
              ticket: _ticket!,
              recentTicket: _recentTicket,
              actionLoading: _isActionLoading,
              onCancel: _canCancel(_ticket!) ? _cancelTicket : null,
              onConfirmTreatment: _canConfirmTreatment(_ticket!)
                  ? _confirmTreatment
                  : null,
            )
          else if (_recentTicket != null)
            _RecentTicketPreview(ticket: _recentTicket!),
        ],
      ),
    );
  }

  bool _canCancel(PublicTicket ticket) {
    return ticket.status == 'CREATED' || ticket.status == 'RECEIVED';
  }

  bool _canConfirmTreatment(PublicTicket ticket) {
    return ticket.status == 'TREATED';
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Champ requis';
    }
    return null;
  }
}

class _TicketSummary extends StatelessWidget {
  const _TicketSummary({
    required this.ticket,
    required this.recentTicket,
    required this.actionLoading,
    required this.onCancel,
    required this.onConfirmTreatment,
  });

  final PublicTicket ticket;
  final RecentTicketEntry? recentTicket;
  final bool actionLoading;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirmTreatment;

  @override
  Widget build(BuildContext context) {
    final itemNamesById = {
      for (final item in recentTicket?.items ?? const <RecentTicketItemEntry>[])
        item.itemId: item.name,
    };
    final createdAtLabel = _dateLabel(ticket.createdAt);
    final updatedAtLabel = ticket.updatedAt == null
        ? null
        : _dateLabel(ticket.updatedAt!);
    final companyName = recentTicket?.companyName;
    final serviceName = recentTicket?.serviceUnitName;
    final locationName = recentTicket?.locationName;
    final showLocation = !_isDefaultLocationName(locationName);
    final contextLabel = _ticketContextLabel(
      companyName: companyName,
      serviceName: serviceName,
      locationName: showLocation ? locationName : null,
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
                          if (contextLabel != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              contextLabel,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: FlowMovaColors.slate,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            'Cree le $createdAtLabel',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: FlowMovaColors.slate),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(status: ticket.status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _TicketProgress(status: ticket.status),
            const SizedBox(height: 16),
            Wrap(
              runSpacing: 10,
              spacing: 10,
              children: [
                _TicketInfoPill(
                  icon: Icons.room_service_outlined,
                  label: 'Service',
                  value: serviceName ?? ticket.serviceUnitId,
                ),
                if (showLocation)
                  _TicketInfoPill(
                    icon: Icons.place_outlined,
                    label: 'Emplacement',
                    value: locationName ?? ticket.locationId,
                  ),
                if (ticket.guestName != null)
                  _TicketInfoPill(
                    icon: Icons.person_outline,
                    label: 'Client',
                    value: ticket.guestName!,
                  ),
                _TicketInfoPill(
                  icon: Icons.payments_outlined,
                  label: 'Total',
                  value: ticket.totalLabel,
                ),
                if (updatedAtLabel != null)
                  _TicketInfoPill(
                    icon: Icons.update_outlined,
                    label: 'Mis a jour',
                    value: updatedAtLabel,
                  ),
              ],
            ),
            if (ticket.notes != null && ticket.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              _TicketNote(note: ticket.notes!),
            ],
            const SizedBox(height: 18),
            _SectionTitle(
              icon: Icons.shopping_bag_outlined,
              label: 'Articles commandes',
            ),
            const SizedBox(height: 8),
            if (ticket.lines.isEmpty)
              const _EmptyLineItems()
            else
              for (final line in ticket.lines)
                _TicketLineTile(
                  line: line,
                  name: itemNamesById[line.itemId] ?? line.itemId,
                ),
            const SizedBox(height: 16),
            _TicketActions(
              actionLoading: actionLoading,
              onCancel: onCancel,
              onConfirmTreatment: onConfirmTreatment,
            ),
            const SizedBox(height: 12),
            const _LookupMessage(
              icon: Icons.verified_user_outlined,
              text:
                  'Statut rafraichi depuis le backend. Gardez le code d acces pour les prochaines actions.',
              color: FlowMovaColors.primaryAqua,
            ),
          ],
        ),
      ),
    );
  }

  static String _dateLabel(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} $hour:$minute';
  }

  static String? _ticketContextLabel({
    required String? companyName,
    required String? serviceName,
    required String? locationName,
  }) {
    final parts = [companyName, serviceName, locationName]
        .where((part) => part != null && part.trim().isNotEmpty)
        .cast<String>()
        .toList(growable: false);
    return parts.isEmpty ? null : parts.join(' - ');
  }

  static bool _isDefaultLocationName(String? locationName) {
    final normalized = locationName?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return true;
    }
    return normalized == 'accueil' ||
        normalized == 'principal' ||
        normalized == 'default' ||
        normalized == 'emplacement par defaut' ||
        normalized == 'emplacement par défaut';
  }
}

class _TicketProgress extends StatelessWidget {
  const _TicketProgress({required this.status});

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
                      child: _ProgressStep(
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

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({required this.label, required this.active});

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

class _TicketInfoPill extends StatelessWidget {
  const _TicketInfoPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 300),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: FlowMovaColors.cloud,
          borderRadius: BorderRadius.circular(FlowMovaRadii.medium),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: FlowMovaColors.slate),
              const SizedBox(width: 8),
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});

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

class _TicketNote extends StatelessWidget {
  const _TicketNote({required this.note});

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

class _EmptyLineItems extends StatelessWidget {
  const _EmptyLineItems();

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

class _TicketLineTile extends StatelessWidget {
  const _TicketLineTile({required this.line, required this.name});

  final PublicTicketLine line;
  final String name;

  @override
  Widget build(BuildContext context) {
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

class _TicketActions extends StatelessWidget {
  const _TicketActions({
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
        const _SectionTitle(icon: Icons.touch_app_outlined, label: 'Actions'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (onCancel != null)
              OutlinedButton.icon(
                onPressed: actionLoading ? null : onCancel,
                icon: actionLoading
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cancel_outlined),
                label: const Text('Annuler le ticket'),
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

class _RecentTicketPreview extends StatelessWidget {
  const _RecentTicketPreview({required this.ticket});

  final RecentTicketEntry ticket;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FlowMovaColors.cloud,
        borderRadius: BorderRadius.circular(FlowMovaRadii.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ticket recent charge localement',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text('${ticket.companyName} - ${ticket.serviceUnitName}'),
            Text('${ticket.locationName} - ${ticket.status}'),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          _statusLabel(status),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
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

class _LookupMessage extends StatelessWidget {
  const _LookupMessage({
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
