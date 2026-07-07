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
  String? _errorMessage;

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
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _lookup,
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
            _TicketSummary(ticket: _ticket!, recentTicket: _recentTicket)
          else if (_recentTicket != null)
            _RecentTicketPreview(ticket: _recentTicket!),
        ],
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Champ requis';
    }
    return null;
  }
}

class _TicketSummary extends StatelessWidget {
  const _TicketSummary({required this.ticket, required this.recentTicket});

  final PublicTicket ticket;
  final RecentTicketEntry? recentTicket;

  @override
  Widget build(BuildContext context) {
    final itemNamesById = {
      for (final item in recentTicket?.items ?? const <RecentTicketItemEntry>[])
        item.itemId: item.name,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ticket.ticketNumber,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _StatusBadge(status: ticket.status),
              ],
            ),
            const SizedBox(height: 12),
            _TicketInfoRow(
              label: 'Service',
              value: recentTicket?.serviceUnitName ?? ticket.serviceUnitId,
            ),
            _TicketInfoRow(
              label: 'Emplacement',
              value: recentTicket?.locationName ?? ticket.locationId,
            ),
            if (ticket.guestName != null)
              _TicketInfoRow(label: 'Client', value: ticket.guestName!),
            _TicketInfoRow(label: 'Total', value: ticket.totalLabel),
            const SizedBox(height: 12),
            Text(
              'Articles commandes',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (ticket.lines.isEmpty)
              const Text('Aucun article associe a ce ticket.')
            else
              for (final line in ticket.lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${itemNamesById[line.itemId] ?? line.itemId} x${line.quantity}',
                  ),
                ),
            const SizedBox(height: 10),
            const _LookupMessage(
              icon: Icons.verified_user_outlined,
              text:
                  'Statut rafraichi depuis le backend. Le code reste necessaire pour les prochaines actions sur ce ticket.',
              color: FlowMovaColors.primaryAqua,
            ),
          ],
        ),
      ),
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

class _TicketInfoRow extends StatelessWidget {
  const _TicketInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: FlowMovaColors.slate),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
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
          status,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
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
