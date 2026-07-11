import 'package:flutter/material.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/theme/flow_mova_colors.dart';
import '../../tickets/data/current_user_ticket_gateway.dart';
import '../data/admin_service_units_gateway.dart';

class BusinessTicketDetailArguments {
  const BusinessTicketDetailArguments({
    required this.companyId,
    required this.ticket,
    required this.gateway,
  });

  final String companyId;
  final CurrentUserTicket ticket;
  final AdminServiceUnitsGateway gateway;
}

class BusinessTicketDetailScreen extends StatefulWidget {
  const BusinessTicketDetailScreen({super.key, required this.arguments});

  final BusinessTicketDetailArguments arguments;

  @override
  State<BusinessTicketDetailScreen> createState() =>
      _BusinessTicketDetailScreenState();
}

class _BusinessTicketDetailScreenState
    extends State<BusinessTicketDetailScreen> {
  late CurrentUserTicket _ticket = widget.arguments.ticket;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return PopScope<CurrentUserTicket>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        Navigator.pop(context, _ticket);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeaderCard(ticket: _ticket),
                const SizedBox(height: 12),
                _CustomerCard(ticket: _ticket),
                const SizedBox(height: 12),
                _TicketInfoCard(ticket: _ticket),
                if (_ticket.notes != null &&
                    _ticket.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _NoteCard(note: _ticket.notes!.trim()),
                ],
                const SizedBox(height: 12),
                _LinesCard(ticket: _ticket),
                const SizedBox(height: 12),
                _ActionsCard(
                  ticket: _ticket,
                  submitting: _submitting,
                  onReceive: _ticket.status == 'CREATED'
                      ? () => _confirmStatus('RECEIVED', 'Marquer recu')
                      : null,
                  onTreat:
                      _ticket.status == 'CREATED' ||
                          _ticket.status == 'RECEIVED'
                      ? () => _confirmStatus('TREATED', 'Marquer traite')
                      : null,
                  onClose: _canClose(_ticket)
                      ? () => _confirmStatus(
                          'CLOSED',
                          'Terminer',
                          irreversible: true,
                        )
                      : null,
                  onCancel:
                      _ticket.status == 'CREATED' ||
                          _ticket.status == 'RECEIVED'
                      ? () => _confirmStatus(
                          'CANCELLED',
                          'Annuler',
                          irreversible: true,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _canClose(CurrentUserTicket ticket) {
    return ticket.status == 'CREATED' ||
        ticket.status == 'RECEIVED' ||
        ticket.status == 'TREATED' ||
        ticket.status == 'CUSTOMER_CONFIRMED';
  }

  Future<void> _confirmStatus(
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
              ? 'Ticket ${_ticket.ticketNumber}. Cette action est definitive.'
              : 'Ticket ${_ticket.ticketNumber}',
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

    setState(() => _submitting = true);
    try {
      final updated = await widget.arguments.gateway.changeTicketStatus(
        widget.arguments.companyId,
        _ticket.serviceUnitId,
        _ticket.id,
        status,
      );
      if (!mounted) {
        return;
      }
      setState(() => _ticket = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ticket ${_ticket.ticketNumber} mis a jour')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de modifier ce ticket.')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.ticket});

  final CurrentUserTicket ticket;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
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
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: FlowMovaColors.logoInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _StatusPill(label: ticketStatusLabel(ticket.status)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ticket.companyName,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: FlowMovaColors.slate,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.room_service_outlined,
                  label: ticket.serviceUnitName,
                ),
                if (!ticket.locationDefault &&
                    ticket.locationName.trim().isNotEmpty)
                  _InfoChip(
                    icon: Icons.place_outlined,
                    label: ticket.locationName,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.ticket});

  final CurrentUserTicket ticket;

  @override
  Widget build(BuildContext context) {
    final name = ticket.guestName?.trim().isNotEmpty == true
        ? ticket.guestName!.trim()
        : ticket.userId.isNotEmpty
        ? 'Client connecte'
        : 'Invite';
    final phone = ticket.customerPhone?.trim();

    return _SectionCard(
      title: 'Client',
      icon: Icons.person_outline,
      child: Column(
        children: [
          _InfoRow(label: 'Nom', value: name),
          const SizedBox(height: 8),
          _InfoRow(
            label: 'Telephone',
            value: phone == null || phone.isEmpty ? 'Non renseigne' : phone,
          ),
        ],
      ),
    );
  }
}

class _TicketInfoCard extends StatelessWidget {
  const _TicketInfoCard({required this.ticket});

  final CurrentUserTicket ticket;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Informations',
      icon: Icons.info_outline,
      child: Column(
        children: [
          _InfoRow(label: 'Cree le', value: _formatDate(ticket.createdAt)),
          if (ticket.updatedAt != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Mis a jour',
              value: _formatDate(ticket.updatedAt!),
            ),
          ],
          if (ticket.closedAt != null) ...[
            const SizedBox(height: 8),
            _InfoRow(label: 'Ferme le', value: _formatDate(ticket.closedAt!)),
          ],
          const SizedBox(height: 8),
          _InfoRow(label: 'Total', value: ticket.totalLabel),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Note client',
      icon: Icons.notes_outlined,
      child: Text(note),
    );
  }
}

class _LinesCard extends StatelessWidget {
  const _LinesCard({required this.ticket});

  final CurrentUserTicket ticket;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Articles commandes',
      icon: Icons.shopping_bag_outlined,
      child: ticket.lines.isEmpty
          ? const Text(
              'Aucun article commande',
              style: TextStyle(color: FlowMovaColors.slate),
            )
          : Column(
              children: [
                for (final line in ticket.lines) ...[
                  _LineTile(line: line, currency: ticket.currency),
                  if (line != ticket.lines.last) const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _ActionsCard extends StatelessWidget {
  const _ActionsCard({
    required this.ticket,
    required this.submitting,
    required this.onReceive,
    required this.onTreat,
    required this.onClose,
    required this.onCancel,
  });

  final CurrentUserTicket ticket;
  final bool submitting;
  final VoidCallback? onReceive;
  final VoidCallback? onTreat;
  final VoidCallback? onClose;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final hasAction =
        onReceive != null ||
        onTreat != null ||
        onClose != null ||
        onCancel != null;

    return _SectionCard(
      title: 'Actions',
      icon: Icons.tune_outlined,
      child: hasAction
          ? Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onReceive != null)
                  FilledButton.tonalIcon(
                    onPressed: submitting ? null : onReceive,
                    icon: const Icon(Icons.inbox_outlined),
                    label: const Text('Recu'),
                  ),
                if (onTreat != null)
                  FilledButton.tonalIcon(
                    onPressed: submitting ? null : onTreat,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Traite'),
                  ),
                if (onClose != null)
                  FilledButton.icon(
                    onPressed: submitting ? null : onClose,
                    icon: const Icon(Icons.done_all_outlined),
                    label: const Text('Terminer'),
                  ),
                if (onCancel != null)
                  OutlinedButton.icon(
                    onPressed: submitting ? null : onCancel,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Annuler'),
                  ),
              ],
            )
          : Text(
              'Aucune action disponible pour le statut ${ticketStatusLabel(ticket.status).toLowerCase()}.',
              style: const TextStyle(color: FlowMovaColors.slate),
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: FlowMovaColors.primaryAqua),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: FlowMovaColors.logoInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              color: FlowMovaColors.slate,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: FlowMovaColors.logoInk,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({required this.line, required this.currency});

  final CurrentUserTicketLine line;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: FlowMovaColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            _LineImage(imageUrl: line.itemImageUrl),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.itemName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'x${line.quantity} - ${line.unitPriceAmount.toStringAsFixed(2)} $currency',
                    style: const TextStyle(color: FlowMovaColors.slate),
                  ),
                  if (line.notes != null && line.notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(line.notes!.trim()),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${line.lineTotalAmount.toStringAsFixed(2)} $currency',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineImage extends StatelessWidget {
  const _LineImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = _absoluteImageUrl(imageUrl);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 54,
        height: 54,
        child: url == null
            ? const _LineImageFallback()
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _LineImageFallback(),
              ),
      ),
    );
  }
}

class _LineImageFallback extends StatelessWidget {
  const _LineImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FlowMovaColors.cloud,
      alignment: Alignment.center,
      child: const Icon(
        Icons.shopping_bag_outlined,
        color: FlowMovaColors.primaryAqua,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      side: BorderSide.none,
      backgroundColor: FlowMovaColors.cloud,
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

String ticketStatusLabel(String status) {
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

String _formatDate(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/'
      '${local.year} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

String? _absoluteImageUrl(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  final uri = Uri.tryParse(trimmed);
  if (uri == null) {
    return null;
  }
  if (uri.hasScheme) {
    return trimmed;
  }
  return Uri.parse(
    AppEnvironment.current.apiBaseUrl,
  ).resolveUri(uri).toString();
}
