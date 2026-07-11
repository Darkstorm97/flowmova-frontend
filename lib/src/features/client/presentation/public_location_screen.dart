import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/session/session_scope.dart';
import '../../../core/theme/flow_mova_colors.dart';
import '../../../core/theme/flow_mova_radii.dart';
import '../../tickets/data/recent_ticket_storage.dart';
import '../../tickets/data/ticket_creation_gateway.dart';
import '../../tickets/presentation/ticket_creation_success_screen.dart';
import '../data/company_detail_gateway.dart';
import '../data/public_location_gateway.dart';

class PublicLocationScreen extends StatefulWidget {
  const PublicLocationScreen({
    super.key,
    this.initialSlug,
    this.gateway,
    this.ticketCreationGateway,
    this.recentTicketStorage,
  });

  final String? initialSlug;
  final PublicLocationGateway? gateway;
  final TicketCreationGateway? ticketCreationGateway;
  final RecentTicketStorage? recentTicketStorage;

  @override
  State<PublicLocationScreen> createState() => _PublicLocationScreenState();
}

class _PublicLocationScreenState extends State<PublicLocationScreen> {
  final _slugController = TextEditingController();
  final _guestNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _selectedItemIds = <String>{};
  final _itemQuantities = <String, int>{};

  late final PublicLocationGateway _gateway =
      widget.gateway ?? BackendPublicLocationGateway(ApiClient());
  late final TicketCreationGateway _ticketCreationGateway =
      widget.ticketCreationGateway ??
      BackendTicketCreationGateway(
        ApiClient(accessTokenProvider: _accessTokenProvider),
      );
  late final RecentTicketStorage _recentTicketStorage =
      widget.recentTicketStorage ?? InMemoryRecentTicketStorage();

  PublicLocationAccess? _access;
  String? _loadedSlug;
  String? _errorMessage;
  bool _loading = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final initialSlug = _normalizeSlug(widget.initialSlug);
    if (initialSlug != null) {
      _slugController.text = initialSlug;
      _load(initialSlug);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: _buildContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final access = _access;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _QrIntroCard(
          slugController: _slugController,
          loading: _loading,
          onSubmit: _submitSlug,
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          _InlineError(message: _errorMessage!),
        ],
        if (_loading) ...[
          const SizedBox(height: 18),
          const Center(child: CircularProgressIndicator()),
        ],
        if (access != null) ...[
          const SizedBox(height: 18),
          _PublicLocationContextCard(access: access),
          const SizedBox(height: 14),
          if (!access.canCreateTicket) ...[
            _InlineNotice(
              icon: Icons.do_not_disturb_on,
              message: !access.company.isOperationallyOpen
                  ? 'Cette entreprise est fermee pour le moment.'
                  : 'Ce service est indisponible pour le moment.',
            ),
          ] else ...[
            _OrderForm(
              access: access,
              selectedItemIds: _selectedItemIds,
              itemQuantities: _itemQuantities,
              guestNameController: _guestNameController,
              phoneController: _phoneController,
              notesController: _notesController,
              submitting: _submitting,
              onToggleItem: _toggleItem,
              onQuantityChanged: _setItemQuantity,
              onSubmit: _submitTicket,
            ),
          ],
        ],
      ],
    );
  }

  Future<void> _submitSlug() async {
    final slug = _normalizeSlug(_slugController.text);
    if (slug == null) {
      setState(() => _errorMessage = 'Collez un code ou un lien QR valide.');
      return;
    }

    await _load(slug);
  }

  Future<void> _load(String publicAccessSlug) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _access = null;
      _selectedItemIds.clear();
      _itemQuantities.clear();
    });

    try {
      final access = await _gateway.getAccess(publicAccessSlug);
      if (!mounted) {
        return;
      }

      setState(() {
        _access = access;
        _loadedSlug = publicAccessSlug;
      });
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } on FormatException {
      if (mounted) {
        setState(() => _errorMessage = 'Le QR code est illisible.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Impossible de charger ce QR code.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _submitTicket() async {
    final access = _access;
    final slug = _loadedSlug;
    if (access == null || slug == null) {
      setState(() => _errorMessage = 'Chargez un QR code avant de commander.');
      return;
    }

    final isAuthenticated =
        SessionScope.maybeOf(context)?.isAuthenticated ?? false;
    if (!isAuthenticated && _guestNameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Indiquez votre nom pour confirmer.');
      return;
    }

    if (!access.serviceUnit.allowTicketWithoutItems &&
        _selectedItemIds.isEmpty) {
      setState(
        () => _errorMessage =
            'Ce service exige au moins un article pour creer une commande.',
      );
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final result = await _ticketCreationGateway
          .createTicketFromPublicLocation(
            slug,
            CreateTicketCommand(
              locationId: access.location.id,
              guestName: isAuthenticated ? null : _guestNameController.text,
              customerPhone: _phoneController.text,
              notes: _notesController.text,
              lines: [
                for (final itemId in _selectedItemIds)
                  CreateTicketLineCommand(
                    itemId: itemId,
                    quantity: _itemQuantities[itemId] ?? 1,
                  ),
              ],
            ),
          );

      final recentTicket = _recentTicketEntry(result, access);
      await _saveRecentTicket(recentTicket);

      if (mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.ticketCreationSuccess,
          arguments: TicketCreationSuccessArguments(
            ticketId: result.id,
            ticketNumber: result.ticketNumber,
            accessCode: result.accessCode,
            companyName: access.company.name,
            serviceUnitName: access.serviceUnit.name,
            locationName: access.location.name,
            locationDefault: access.location.defaultLocation,
            totalLabel: result.totalLabel,
            recentTicket: result.accessCode == null ? null : recentTicket,
            items: [
              for (final item in access.items)
                if (_selectedItemIds.contains(item.id))
                  TicketCreationSuccessItem(
                    itemId: item.id,
                    name: item.catalog.name,
                    quantity: _itemQuantities[item.id] ?? 1,
                  ),
            ],
          ),
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } on FormatException {
      if (mounted) {
        setState(() => _errorMessage = 'La reponse ticket est illisible.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Impossible de creer la commande.');
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  RecentTicketEntry _recentTicketEntry(
    TicketCreationResult ticket,
    PublicLocationAccess access,
  ) {
    return RecentTicketEntry(
      id: ticket.id,
      ticketNumber: ticket.ticketNumber,
      accessCode: ticket.accessCode,
      guestName: ticket.guestName,
      customerPhone: ticket.customerPhone,
      serviceUnitId: access.serviceUnit.id,
      locationId: access.location.id,
      companyId: access.company.id,
      status: ticket.status,
      createdAt: DateTime.now(),
      companyName: access.company.name,
      serviceUnitName: access.serviceUnit.name,
      locationName: access.location.name,
      totalLabel: ticket.totalLabel,
      items: [
        for (final item in access.items)
          if (_selectedItemIds.contains(item.id))
            RecentTicketItemEntry(
              itemId: item.id,
              name: item.catalog.name,
              quantity: _itemQuantities[item.id] ?? 1,
            ),
      ],
    );
  }

  Future<void> _saveRecentTicket(RecentTicketEntry ticket) async {
    if (SessionScope.maybeOf(context)?.isAuthenticated ?? false) {
      return;
    }

    try {
      await _recentTicketStorage.save(ticket);
    } catch (_) {
      // Local recents are helpful but should never block ticket creation.
    }
  }

  void _toggleItem(String itemId, bool selected) {
    setState(() {
      if (selected) {
        _selectedItemIds.add(itemId);
        _itemQuantities[itemId] = _itemQuantities[itemId] ?? 1;
      } else {
        _selectedItemIds.remove(itemId);
        _itemQuantities.remove(itemId);
      }
    });
  }

  void _setItemQuantity(String itemId, int quantity) {
    setState(() => _itemQuantities[itemId] = quantity);
  }

  String? _normalizeSlug(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final parsed = Uri.tryParse(raw);
    final querySlug = parsed?.queryParameters['slug'];
    if (querySlug != null && querySlug.trim().isNotEmpty) {
      return querySlug.trim();
    }

    final segments = parsed?.pathSegments ?? const <String>[];
    if (segments.isNotEmpty && segments.last.trim().isNotEmpty) {
      return segments.last.trim();
    }

    return raw;
  }

  Future<String?> _accessTokenProvider() {
    final session = SessionScope.maybeOf(context);
    return session?.currentAccessToken() ?? Future.value();
  }

  @override
  void dispose() {
    _slugController.dispose();
    _guestNameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

class _QrIntroCard extends StatelessWidget {
  const _QrIntroCard({
    required this.slugController,
    required this.loading,
    required this.onSubmit,
  });

  final TextEditingController slugController;
  final bool loading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: FlowMovaColors.primaryAqua.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(FlowMovaRadii.medium),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.qr_code_2_outlined),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Commande sur place',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: FlowMovaColors.logoInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: slugController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit(),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.link_outlined),
                labelText: 'Code ou lien QR',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: loading ? null : onSubmit,
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward),
              label: const Text('Continuer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublicLocationContextCard extends StatelessWidget {
  const _PublicLocationContextCard({required this.access});

  final PublicLocationAccess access;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              access.company.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: FlowMovaColors.logoInk,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.room_service_outlined,
              label: access.serviceUnit.name,
            ),
            const SizedBox(height: 6),
            _InfoRow(icon: Icons.place_outlined, label: access.location.name),
          ],
        ),
      ),
    );
  }
}

class _OrderForm extends StatelessWidget {
  const _OrderForm({
    required this.access,
    required this.selectedItemIds,
    required this.itemQuantities,
    required this.guestNameController,
    required this.phoneController,
    required this.notesController,
    required this.submitting,
    required this.onToggleItem,
    required this.onQuantityChanged,
    required this.onSubmit,
  });

  final PublicLocationAccess access;
  final Set<String> selectedItemIds;
  final Map<String, int> itemQuantities;
  final TextEditingController guestNameController;
  final TextEditingController phoneController;
  final TextEditingController notesController;
  final bool submitting;
  final void Function(String itemId, bool selected) onToggleItem;
  final void Function(String itemId, int quantity) onQuantityChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final isAuthenticated =
        SessionScope.maybeOf(context)?.isAuthenticated ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (access.items.isNotEmpty) ...[
          Text(
            'Articles optionnels',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (final item in access.items) ...[
            _QrItemTile(
              item: item,
              selected: selectedItemIds.contains(item.id),
              quantity: itemQuantities[item.id] ?? 1,
              onToggle: (selected) => onToggleItem(item.id, selected),
              onQuantityChanged: (quantity) =>
                  onQuantityChanged(item.id, quantity),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 6),
        ],
        if (!isAuthenticated) ...[
          TextField(
            controller: guestNameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person_outline),
              labelText: 'Nom',
            ),
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.phone_outlined),
            labelText: 'Telephone optionnel',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: notesController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.notes_outlined),
            labelText: 'Notes optionnelles',
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: submitting ? null : onSubmit,
          icon: submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: const Text('Creer ma commande'),
        ),
      ],
    );
  }
}

class _QrItemTile extends StatelessWidget {
  const _QrItemTile({
    required this.item,
    required this.selected,
    required this.quantity,
    required this.onToggle,
    required this.onQuantityChanged,
  });

  final CompanyServiceUnitAvailableItem item;
  final bool selected;
  final int quantity;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: selected
          ? FlowMovaColors.primaryAqua.withValues(alpha: 0.08)
          : null,
      child: ListTile(
        onTap: () => onToggle(!selected),
        leading: Checkbox(
          value: selected,
          onChanged: (value) => onToggle(value ?? false),
        ),
        title: Text(item.catalog.name),
        subtitle: Text(item.priceLabel),
        trailing: selected
            ? DropdownButton<int>(
                value: quantity,
                items: [
                  for (var value = 1; value <= 9; value++)
                    DropdownMenuItem(value: value, child: Text('x$value')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onQuantityChanged(value);
                  }
                },
              )
            : null,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: FlowMovaColors.slate),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: FlowMovaColors.logoInk,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
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
        color: FlowMovaColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(FlowMovaRadii.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: FlowMovaColors.error,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FlowMovaColors.primaryAqua.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(FlowMovaRadii.medium),
        border: Border.all(
          color: FlowMovaColors.primaryAqua.withValues(alpha: 0.22),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: FlowMovaColors.primaryAqua),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: FlowMovaColors.logoInk,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
