import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/session/session_scope.dart';
import '../../../core/theme/flow_mova_colors.dart';
import '../../../core/theme/flow_mova_radii.dart';
import '../../../shared/widgets/flow_mova_app_bar_title.dart';
import '../../tickets/data/recent_ticket_storage.dart';
import '../../tickets/data/ticket_creation_gateway.dart';
import '../data/company_detail_gateway.dart';

class CompanyDetailScreen extends StatefulWidget {
  const CompanyDetailScreen({
    required this.companyId,
    super.key,
    this.detailGateway,
    this.ticketCreationGateway,
    this.recentTicketStorage,
  });

  final String companyId;
  final CompanyDetailGateway? detailGateway;
  final TicketCreationGateway? ticketCreationGateway;
  final RecentTicketStorage? recentTicketStorage;

  @override
  State<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<CompanyDetailScreen> {
  late final CompanyDetailGateway _detailGateway =
      widget.detailGateway ?? BackendCompanyDetailGateway(ApiClient());

  late final RecentTicketStorage _recentTicketStorage =
      widget.recentTicketStorage ?? InMemoryRecentTicketStorage();

  late Future<CompanyDetailBundle> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = _detailGateway.getDetail(widget.companyId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const FlowMovaAppBarTitle(title: 'Entreprise', showLogo: false),
      ),
      body: ColoredBox(
        color: FlowMovaColors.cloud,
        child: SafeArea(
          top: false,
          child: FutureBuilder<CompanyDetailBundle>(
            future: _detailFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const _DetailLoading();
              }

              if (snapshot.hasError) {
                return _DetailError(
                  message: _errorMessage(snapshot.error),
                  onRetry: () {
                    setState(() {
                      _detailFuture = _detailGateway.getDetail(
                        widget.companyId,
                      );
                    });
                  },
                );
              }

              final bundle = snapshot.requireData;
              final ticketCreationGateway =
                  widget.ticketCreationGateway ??
                  BackendTicketCreationGateway(
                    ApiClient(accessTokenProvider: _accessTokenProvider),
                  );
              return SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: _CompanyDetailContent(
                        bundle: bundle,
                        detailGateway: _detailGateway,
                        ticketCreationGateway: ticketCreationGateway,
                        recentTicketStorage: _recentTicketStorage,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _errorMessage(Object? error) {
    if (error is ApiException) {
      return error.message;
    }
    if (error is FormatException) {
      return 'La fiche entreprise est illisible.';
    }
    return 'Impossible de charger cette entreprise.';
  }

  Future<String?> _accessTokenProvider() async {
    final element = context
        .getElementForInheritedWidgetOfExactType<SessionScope>();
    final scope = element?.widget;
    if (scope is! SessionScope) {
      return null;
    }

    return scope.notifier?.currentAccessToken();
  }
}

class _CompanyDetailContent extends StatelessWidget {
  const _CompanyDetailContent({
    required this.bundle,
    required this.detailGateway,
    required this.ticketCreationGateway,
    required this.recentTicketStorage,
  });

  final CompanyDetailBundle bundle;
  final CompanyDetailGateway detailGateway;
  final TicketCreationGateway ticketCreationGateway;
  final RecentTicketStorage recentTicketStorage;

  @override
  Widget build(BuildContext context) {
    final company = bundle.company;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CompanyHero(
          company: company,
          bundle: bundle,
          detailGateway: detailGateway,
          ticketCreationGateway: ticketCreationGateway,
          recentTicketStorage: recentTicketStorage,
        ),
        const SizedBox(height: 16),
        _ServiceUnitsSection(serviceUnits: bundle.serviceUnits),
        const SizedBox(height: 18),
        _CatalogSection(
          catalogs: bundle.catalogs,
          categories: bundle.catalogCategories,
        ),
      ],
    );
  }
}

class _CompanyHero extends StatelessWidget {
  const _CompanyHero({
    required this.company,
    required this.bundle,
    required this.detailGateway,
    required this.ticketCreationGateway,
    required this.recentTicketStorage,
  });

  final CompanyDetail company;
  final CompanyDetailBundle bundle;
  final CompanyDetailGateway detailGateway;
  final TicketCreationGateway ticketCreationGateway;
  final RecentTicketStorage recentTicketStorage;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailImage(company: company),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        company.name,
                        style: textTheme.headlineSmall?.copyWith(
                          color: FlowMovaColors.logoInk,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _OperationalStatusPill(status: company.operationalStatus),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoPill(
                      icon: _businessTypeIcon(company.businessType),
                      label: _businessTypeLabel(company.businessType),
                    ),
                    _InfoPill(
                      icon: Icons.place_outlined,
                      label: company.locationLabel,
                    ),
                  ],
                ),
                if (company.description != null &&
                    company.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    company.description!,
                    style: textTheme.bodyLarge?.copyWith(
                      color: FlowMovaColors.slate,
                    ),
                  ),
                ],
                if (!company.isOperationallyOpen) ...[
                  const SizedBox(height: 12),
                  const _CompanyClosedNotice(),
                ],
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.map_outlined, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              company.addressLabel,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _CreateOrderButton(
                      bundle: bundle,
                      detailGateway: detailGateway,
                      ticketCreationGateway: ticketCreationGateway,
                      recentTicketStorage: recentTicketStorage,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailImage extends StatelessWidget {
  const _DetailImage({required this.company});

  final CompanyDetail company;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: _businessTypeColor(company.businessType).withValues(alpha: 0.16),
      child: Center(
        child: Icon(
          _businessTypeIcon(company.businessType),
          size: 42,
          color: _businessTypeColor(company.businessType),
        ),
      ),
    );

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: company.imageUrl == null || company.imageUrl!.trim().isEmpty
          ? fallback
          : Image.network(
              company.imageUrl!.trim(),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            ),
    );
  }
}

class _CreateOrderButton extends StatelessWidget {
  const _CreateOrderButton({
    required this.bundle,
    required this.detailGateway,
    required this.ticketCreationGateway,
    required this.recentTicketStorage,
  });

  final CompanyDetailBundle bundle;
  final CompanyDetailGateway detailGateway;
  final TicketCreationGateway ticketCreationGateway;
  final RecentTicketStorage recentTicketStorage;

  @override
  Widget build(BuildContext context) {
    final hasService = bundle.serviceUnits.isNotEmpty;
    final companyIsOpen = bundle.company.isOperationallyOpen;
    final canCreate = hasService && companyIsOpen;

    return FilledButton.icon(
      onPressed: canCreate
          ? () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => _CreateTicketSheet(
                bundle: bundle,
                detailGateway: detailGateway,
                ticketCreationGateway: ticketCreationGateway,
                recentTicketStorage: recentTicketStorage,
              ),
            )
          : null,
      icon: Icon(
        companyIsOpen ? Icons.add_task_outlined : Icons.do_not_disturb_on,
      ),
      label: Text(
        !companyIsOpen
            ? 'Entreprise fermee'
            : hasService
            ? 'Creer une commande'
            : 'Aucun service ouvert',
      ),
    );
  }
}

class _CreateTicketSheet extends StatefulWidget {
  const _CreateTicketSheet({
    required this.bundle,
    required this.detailGateway,
    required this.ticketCreationGateway,
    required this.recentTicketStorage,
  });

  final CompanyDetailBundle bundle;
  final CompanyDetailGateway detailGateway;
  final TicketCreationGateway ticketCreationGateway;
  final RecentTicketStorage recentTicketStorage;

  @override
  State<_CreateTicketSheet> createState() => _CreateTicketSheetState();
}

class _CreateTicketSheetState extends State<_CreateTicketSheet> {
  final _guestNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _selectedItemIds = <String>{};
  final _itemQuantities = <String, int>{};

  CompanyServiceUnitItem? _selectedServiceUnit;
  CompanyServiceUnitDetail? _serviceUnitDetail;
  CompanyServiceUnitLocation? _selectedLocation;
  _TicketConfirmation? _createdTicket;
  String? _errorMessage;
  bool _loadingServiceUnit = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.bundle.serviceUnits.length == 1) {
      _selectServiceUnit(widget.bundle.serviceUnits.single);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.55,
        maxChildSize: 0.96,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: _createdTicket == null
                  ? _buildForm(context)
                  : _TicketCreatedSummary(confirmation: _createdTicket!),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final canChangeService = widget.bundle.serviceUnits.length > 1;
    final canChangeLocation =
        _serviceUnitDetail != null && _serviceUnitDetail!.locations.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: FlowMovaColors.border,
              borderRadius: BorderRadius.circular(FlowMovaRadii.pill),
            ),
            child: const SizedBox(width: 48, height: 4),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Creer une commande',
          style: textTheme.headlineSmall?.copyWith(
            color: FlowMovaColors.logoInk,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.bundle.company.name,
          style: textTheme.bodyLarge?.copyWith(color: FlowMovaColors.slate),
        ),
        const SizedBox(height: 18),
        _ChoiceSummaryTile(
          icon: Icons.room_service_outlined,
          label: 'Service',
          value: _selectedServiceUnit?.name ?? 'A selectionner',
          actionLabel: _selectedServiceUnit == null ? 'Choisir' : 'Modifier',
          onTap: canChangeService ? _openServicePicker : null,
        ),
        const SizedBox(height: 12),
        if (_loadingServiceUnit) ...[
          const Center(child: CircularProgressIndicator()),
        ] else if (_serviceUnitDetail != null) ...[
          _ChoiceSummaryTile(
            icon: Icons.place_outlined,
            label: 'Emplacement',
            value: _selectedLocation?.name ?? 'A selectionner',
            actionLabel: _selectedLocation == null ? 'Choisir' : 'Modifier',
            onTap: canChangeLocation ? _openLocationPicker : null,
          ),
          const SizedBox(height: 12),
          _SelectedItemsSummary(
            selectedItems: _selectedItems,
            itemQuantities: _itemQuantities,
            canSelect: _serviceUnitDetail!.items.isNotEmpty,
            onTap: _openItemsPicker,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _guestNameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person_outline),
              labelText: 'Nom',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.phone_outlined),
              labelText: 'Telephone optionnel',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notesController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.notes_outlined),
              labelText: 'Notes optionnelles',
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            _InlineError(message: _errorMessage!),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: const Text('Creer mon ticket'),
          ),
        ],
      ],
    );
  }

  List<CompanyServiceUnitAvailableItem> get _selectedItems {
    final items =
        _serviceUnitDetail?.items ?? const <CompanyServiceUnitAvailableItem>[];
    return items
        .where((item) => _selectedItemIds.contains(item.id))
        .toList(growable: false);
  }

  List<_TicketConfirmationItem> get _selectedConfirmationItems {
    return [
      for (final item in _selectedItems)
        _TicketConfirmationItem(
          itemId: item.id,
          name: item.catalog.name,
          quantity: _itemQuantities[item.id] ?? 1,
        ),
    ];
  }

  Future<void> _openServicePicker() async {
    final serviceUnit = await showModalBottomSheet<CompanyServiceUnitItem>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ServiceSearchSheet(
        serviceUnits: widget.bundle.serviceUnits,
        selectedServiceUnit: _selectedServiceUnit,
      ),
    );

    if (serviceUnit != null) {
      await _selectServiceUnit(serviceUnit);
    }
  }

  Future<void> _openLocationPicker() async {
    final detail = _serviceUnitDetail;
    if (detail == null) {
      return;
    }

    final location = await showModalBottomSheet<CompanyServiceUnitLocation>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _LocationSearchSheet(
        locations: detail.locations,
        selectedLocation: _selectedLocation,
      ),
    );

    if (location != null) {
      setState(() => _selectedLocation = location);
    }
  }

  Future<void> _openItemsPicker() async {
    final detail = _serviceUnitDetail;
    if (detail == null || detail.items.isEmpty) {
      return;
    }

    final result = await showModalBottomSheet<_ItemPickerResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ItemsSearchSheet(
        items: detail.items,
        selectedItemIds: _selectedItemIds,
        itemQuantities: _itemQuantities,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedItemIds
          ..clear()
          ..addAll(result.selectedItemIds);
        _itemQuantities
          ..clear()
          ..addAll(result.itemQuantities);
      });
    }
  }

  Future<void> _selectServiceUnit(CompanyServiceUnitItem serviceUnit) async {
    setState(() {
      _selectedServiceUnit = serviceUnit;
      _serviceUnitDetail = null;
      _selectedLocation = null;
      _selectedItemIds.clear();
      _itemQuantities.clear();
      _errorMessage = null;
      _loadingServiceUnit = true;
    });

    try {
      final detail = await widget.detailGateway.getServiceUnitDetail(
        widget.bundle.company.id,
        serviceUnit.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _serviceUnitDetail = detail;
        _selectedLocation = _initialLocation(detail);
      });
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } on FormatException {
      if (mounted) {
        setState(() => _errorMessage = 'Le service est illisible.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Impossible de charger ce service.');
      }
    } finally {
      if (mounted) {
        setState(() => _loadingServiceUnit = false);
      }
    }
  }

  CompanyServiceUnitLocation? _initialLocation(
    CompanyServiceUnitDetail detail,
  ) {
    if (detail.locations.isEmpty) {
      return detail.defaultLocation;
    }

    return detail.locations.firstWhere(
      (location) => location.defaultLocation,
      orElse: () => detail.locations.first,
    );
  }

  Future<void> _submit() async {
    final serviceUnit = _selectedServiceUnit;
    final location = _selectedLocation;
    if (serviceUnit == null || location == null) {
      setState(
        () => _errorMessage = 'Choisissez un service et un emplacement.',
      );
      return;
    }

    if (_guestNameController.text.trim().isEmpty) {
      setState(
        () => _errorMessage = 'Indiquez votre nom pour creer le ticket.',
      );
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final selectedItems = _selectedConfirmationItems;
      final result = await widget.ticketCreationGateway.createTicket(
        serviceUnit.id,
        CreateTicketCommand(
          locationId: location.id,
          guestName: _guestNameController.text,
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
      final confirmation = _TicketConfirmation(
        ticket: result,
        company: widget.bundle.company,
        serviceUnit: serviceUnit,
        location: location,
        items: selectedItems,
      );

      await _saveRecentTicket(confirmation);

      if (mounted) {
        setState(() => _createdTicket = confirmation);
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
        setState(() => _errorMessage = 'Impossible de creer le ticket.');
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _saveRecentTicket(_TicketConfirmation confirmation) async {
    try {
      await widget.recentTicketStorage.save(confirmation.toRecentTicketEntry());
    } catch (_) {
      // Local recents are helpful but should never block ticket creation.
    }
  }

  @override
  void dispose() {
    _guestNameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

class _ChoiceSummaryTile extends StatelessWidget {
  const _ChoiceSummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FlowMovaColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FlowMovaRadii.medium),
        side: const BorderSide(color: FlowMovaColors.border),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(value),
        trailing: onTap == null
            ? null
            : TextButton(onPressed: onTap, child: Text(actionLabel)),
        onTap: onTap,
      ),
    );
  }
}

class _SelectedItemsSummary extends StatelessWidget {
  const _SelectedItemsSummary({
    required this.selectedItems,
    required this.itemQuantities,
    required this.canSelect,
    required this.onTap,
  });

  final List<CompanyServiceUnitAvailableItem> selectedItems;
  final Map<String, int> itemQuantities;
  final bool canSelect;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final value = selectedItems.isEmpty
        ? canSelect
              ? 'Aucun article selectionne'
              : 'Aucun article disponible'
        : selectedItems
              .map((item) {
                final quantity = itemQuantities[item.id] ?? 1;
                return '${item.catalog.name} x$quantity';
              })
              .join(', ');

    return _ChoiceSummaryTile(
      icon: Icons.shopping_bag_outlined,
      label: 'Articles optionnels',
      value: value,
      actionLabel: selectedItems.isEmpty ? 'Choisir' : 'Modifier',
      onTap: canSelect ? onTap : null,
    );
  }
}

class _ServiceSearchSheet extends StatefulWidget {
  const _ServiceSearchSheet({
    required this.serviceUnits,
    required this.selectedServiceUnit,
  });

  final List<CompanyServiceUnitItem> serviceUnits;
  final CompanyServiceUnitItem? selectedServiceUnit;

  @override
  State<_ServiceSearchSheet> createState() => _ServiceSearchSheetState();
}

class _ServiceSearchSheetState extends State<_ServiceSearchSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.serviceUnits
        .where((serviceUnit) {
          final query = _query.trim().toLowerCase();
          return query.isEmpty ||
              serviceUnit.name.toLowerCase().contains(query) ||
              (serviceUnit.location?.toLowerCase().contains(query) ?? false) ||
              (serviceUnit.description?.toLowerCase().contains(query) ?? false);
        })
        .toList(growable: false);

    return _PickerSheetScaffold(
      title: 'Choisir un service',
      searchHint: 'Rechercher un service',
      onSearchChanged: (value) => setState(() => _query = value),
      child: filtered.isEmpty
          ? const _StateBox(
              icon: Icons.search_off_outlined,
              title: 'Aucun service trouve',
              message: 'Essayez une autre recherche.',
            )
          : Column(
              children: [
                for (final serviceUnit in filtered) ...[
                  _SelectableTile(
                    selected: widget.selectedServiceUnit?.id == serviceUnit.id,
                    icon: Icons.room_service_outlined,
                    title: serviceUnit.name,
                    subtitle: serviceUnit.location,
                    onTap: () => Navigator.pop(context, serviceUnit),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
    );
  }
}

class _LocationSearchSheet extends StatefulWidget {
  const _LocationSearchSheet({
    required this.locations,
    required this.selectedLocation,
  });

  final List<CompanyServiceUnitLocation> locations;
  final CompanyServiceUnitLocation? selectedLocation;

  @override
  State<_LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<_LocationSearchSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.locations
        .where((location) {
          final query = _query.trim().toLowerCase();
          return query.isEmpty ||
              location.name.toLowerCase().contains(query) ||
              location.type.toLowerCase().contains(query) ||
              (location.description?.toLowerCase().contains(query) ?? false);
        })
        .toList(growable: false);

    return _PickerSheetScaffold(
      title: 'Choisir un emplacement',
      searchHint: 'Rechercher un emplacement',
      onSearchChanged: (value) => setState(() => _query = value),
      child: filtered.isEmpty
          ? const _StateBox(
              icon: Icons.search_off_outlined,
              title: 'Aucun emplacement trouve',
              message: 'Essayez une autre recherche.',
            )
          : Column(
              children: [
                for (final location in filtered) ...[
                  _SelectableTile(
                    selected: widget.selectedLocation?.id == location.id,
                    icon: Icons.place_outlined,
                    title: location.name,
                    subtitle: location.defaultLocation
                        ? 'Emplacement par defaut'
                        : location.type,
                    onTap: () => Navigator.pop(context, location),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
    );
  }
}

class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
    required this.selected,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: selected
          ? FlowMovaColors.primaryAqua.withValues(alpha: 0.1)
          : null,
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          selected ? Icons.check_circle : icon,
          color: selected ? FlowMovaColors.primaryAqua : null,
        ),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
      ),
    );
  }
}

class _ItemsSearchSheet extends StatefulWidget {
  const _ItemsSearchSheet({
    required this.items,
    required this.selectedItemIds,
    required this.itemQuantities,
  });

  final List<CompanyServiceUnitAvailableItem> items;
  final Set<String> selectedItemIds;
  final Map<String, int> itemQuantities;

  @override
  State<_ItemsSearchSheet> createState() => _ItemsSearchSheetState();
}

class _ItemsSearchSheetState extends State<_ItemsSearchSheet> {
  late final Set<String> _selectedItemIds;
  late final Map<String, int> _itemQuantities;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selectedItemIds = {...widget.selectedItemIds};
    _itemQuantities = {...widget.itemQuantities};
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items
        .where((item) {
          final query = _query.trim().toLowerCase();
          return query.isEmpty ||
              item.catalog.name.toLowerCase().contains(query) ||
              (item.catalog.description?.toLowerCase().contains(query) ??
                  false);
        })
        .toList(growable: false);

    return _PickerSheetScaffold(
      title: 'Choisir des articles',
      searchHint: 'Rechercher un article',
      onSearchChanged: (value) => setState(() => _query = value),
      footer: FilledButton.icon(
        onPressed: () => Navigator.pop(
          context,
          _ItemPickerResult(
            selectedItemIds: _selectedItemIds,
            itemQuantities: _itemQuantities,
          ),
        ),
        icon: const Icon(Icons.check),
        label: Text('Valider (${_selectedItemIds.length})'),
      ),
      child: filtered.isEmpty
          ? const _StateBox(
              icon: Icons.search_off_outlined,
              title: 'Aucun article trouve',
              message: 'Essayez une autre recherche.',
            )
          : Column(
              children: [
                for (final item in filtered) ...[
                  _ItemSelectionTile(
                    item: item,
                    selected: _selectedItemIds.contains(item.id),
                    quantity: _itemQuantities[item.id] ?? 1,
                    onToggle: (selected) => setState(() {
                      if (selected) {
                        _selectedItemIds.add(item.id);
                        _itemQuantities[item.id] =
                            _itemQuantities[item.id] ?? 1;
                      } else {
                        _selectedItemIds.remove(item.id);
                        _itemQuantities.remove(item.id);
                      }
                    }),
                    onQuantityChanged: (quantity) => setState(() {
                      _selectedItemIds.add(item.id);
                      _itemQuantities[item.id] = quantity.clamp(1, 99);
                    }),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
    );
  }
}

class _PickerSheetScaffold extends StatelessWidget {
  const _PickerSheetScaffold({
    required this.title,
    required this.searchHint,
    required this.onSearchChanged,
    required this.child,
    this.footer,
  });

  final String title;
  final String searchHint;
  final ValueChanged<String> onSearchChanged;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.45,
        maxChildSize: 0.94,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: FlowMovaColors.border,
                        borderRadius: BorderRadius.circular(FlowMovaRadii.pill),
                      ),
                      child: const SizedBox(width: 48, height: 4),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: FlowMovaColors.logoInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: searchHint,
                    ),
                  ),
                  const SizedBox(height: 14),
                  child,
                  if (footer != null) ...[const SizedBox(height: 16), footer!],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ItemPickerResult {
  const _ItemPickerResult({
    required this.selectedItemIds,
    required this.itemQuantities,
  });

  final Set<String> selectedItemIds;
  final Map<String, int> itemQuantities;
}

class _ItemSelectionTile extends StatelessWidget {
  const _ItemSelectionTile({
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
      child: InkWell(
        onTap: () => onToggle(!selected),
        borderRadius: BorderRadius.circular(FlowMovaRadii.small),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Checkbox(
                value: selected,
                onChanged: (value) => onToggle(value ?? false),
              ),
              const SizedBox(width: 4),
              _CatalogThumb(catalog: item.catalog),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.catalog.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.priceLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: FlowMovaColors.slate,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                SizedBox(
                  width: 76,
                  child: DropdownButton<int>(
                    value: quantity,
                    isExpanded: true,
                    items: [
                      for (var quantity = 1; quantity <= 9; quantity++)
                        DropdownMenuItem(
                          value: quantity,
                          child: Text('x$quantity'),
                        ),
                    ],
                    onChanged: (quantity) {
                      if (quantity != null) {
                        onQuantityChanged(quantity);
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedSummary extends StatelessWidget {
  const _SelectedSummary({
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
        color: FlowMovaColors.white,
        borderRadius: BorderRadius.circular(FlowMovaRadii.medium),
        border: Border.all(color: FlowMovaColors.border),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(value),
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

class _TicketConfirmation {
  const _TicketConfirmation({
    required this.ticket,
    required this.company,
    required this.serviceUnit,
    required this.location,
    required this.items,
  });

  final TicketCreationResult ticket;
  final CompanyDetail company;
  final CompanyServiceUnitItem serviceUnit;
  final CompanyServiceUnitLocation location;
  final List<_TicketConfirmationItem> items;

  RecentTicketEntry toRecentTicketEntry() {
    return RecentTicketEntry(
      id: ticket.id,
      ticketNumber: ticket.ticketNumber,
      accessCode: ticket.accessCode,
      guestName: ticket.guestName,
      customerPhone: ticket.customerPhone,
      serviceUnitId: serviceUnit.id,
      locationId: location.id,
      companyId: company.id,
      status: ticket.status,
      createdAt: DateTime.now(),
      companyName: company.name,
      serviceUnitName: serviceUnit.name,
      locationName: location.name,
      totalLabel: ticket.totalLabel,
      items: [
        for (final item in items)
          RecentTicketItemEntry(
            itemId: item.itemId,
            name: item.name,
            quantity: item.quantity,
          ),
      ],
    );
  }
}

class _TicketConfirmationItem {
  const _TicketConfirmationItem({
    required this.itemId,
    required this.name,
    required this.quantity,
  });

  final String itemId;
  final String name;
  final int quantity;

  String get label => '$name x$quantity';
}

class _TicketCreatedSummary extends StatelessWidget {
  const _TicketCreatedSummary({required this.confirmation});

  final _TicketConfirmation confirmation;

  @override
  Widget build(BuildContext context) {
    final ticket = confirmation.ticket;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Icon(
          Icons.check_circle_outline,
          size: 54,
          color: FlowMovaColors.leafGreen,
        ),
        const SizedBox(height: 14),
        Text(
          'Ticket cree',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: FlowMovaColors.logoInk,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        _SelectedSummary(
          icon: Icons.confirmation_number_outlined,
          label: 'Numero de ticket',
          value: ticket.ticketNumber,
        ),
        if (ticket.accessCode != null) ...[
          const SizedBox(height: 10),
          _SelectedSummary(
            icon: Icons.key_outlined,
            label: 'Code acces',
            value: ticket.accessCode!,
          ),
          const SizedBox(height: 10),
          const _InfoMessage(
            icon: Icons.info_outline,
            message:
                'Conservez ce code. Il permettra de confirmer et retrouver votre commande depuis cet appareil ou avec le numero du ticket.',
          ),
        ],
        const SizedBox(height: 10),
        _SelectedSummary(
          icon: Icons.room_service_outlined,
          label: 'Service',
          value: confirmation.serviceUnit.name,
        ),
        const SizedBox(height: 10),
        _SelectedSummary(
          icon: Icons.place_outlined,
          label: 'Emplacement',
          value: confirmation.location.name,
        ),
        if (confirmation.items.isNotEmpty) ...[
          const SizedBox(height: 10),
          _SelectedSummary(
            icon: Icons.shopping_bag_outlined,
            label: 'Articles commandes',
            value: confirmation.items.map((item) => item.label).join(', '),
          ),
        ],
        const SizedBox(height: 10),
        _SelectedSummary(
          icon: Icons.payments_outlined,
          label: 'Total indicatif',
          value: ticket.totalLabel,
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}

class _InfoMessage extends StatelessWidget {
  const _InfoMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FlowMovaColors.primaryAqua.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(FlowMovaRadii.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: FlowMovaColors.primaryAqua),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: FlowMovaColors.ink,
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

class _ServiceUnitsSection extends StatelessWidget {
  const _ServiceUnitsSection({required this.serviceUnits});

  static const _visibleServiceUnitLimit = 5;

  final List<CompanyServiceUnitItem> serviceUnits;

  @override
  Widget build(BuildContext context) {
    final visibleServiceUnits = serviceUnits
        .take(_visibleServiceUnitLimit)
        .toList(growable: false);

    return _Section(
      title: 'Services disponibles',
      emptyMessage: 'Aucun service ouvert pour le moment.',
      isEmpty: serviceUnits.isEmpty,
      child: SizedBox(
        height: 86,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount:
              visibleServiceUnits.length +
              (serviceUnits.length > _visibleServiceUnitLimit ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            if (index < visibleServiceUnits.length) {
              return _ServiceUnitTile(serviceUnit: visibleServiceUnits[index]);
            }

            return _MoreServicesTile(totalServices: serviceUnits.length);
          },
        ),
      ),
    );
  }
}

class _ServiceUnitTile extends StatelessWidget {
  const _ServiceUnitTile({required this.serviceUnit});

  final CompanyServiceUnitItem serviceUnit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 204,
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.serviceUnitDetail),
          borderRadius: BorderRadius.circular(FlowMovaRadii.small),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                const Icon(Icons.room_service_outlined, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceUnit.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (serviceUnit.location != null &&
                              serviceUnit.location!.trim().isNotEmpty)
                            serviceUnit.location!,
                          serviceUnit.status,
                        ].join(' - '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: FlowMovaColors.slate,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoreServicesTile extends StatelessWidget {
  const _MoreServicesTile({required this.totalServices});

  final int totalServices;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: OutlinedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'La liste complete des services avec recherche arrive bientot.',
              ),
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.list_alt_outlined, size: 20),
            const SizedBox(height: 4),
            Text(
              'Voir plus',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              '$totalServices services',
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

class _CatalogSection extends StatefulWidget {
  const _CatalogSection({required this.catalogs, required this.categories});

  final List<CompanyCatalogItem> catalogs;
  final List<CompanyCatalogCategory> categories;

  @override
  State<_CatalogSection> createState() => _CatalogSectionState();
}

class _CatalogSectionState extends State<_CatalogSection> {
  String? _selectedCategoryId;
  String _query = '';

  List<CompanyCatalogCategory> get _visibleCategories {
    final categories = widget.categories
        .where((category) => category.status == 'ACTIVE')
        .toList(growable: false);
    return [...categories]..sort((left, right) {
      final orderComparison = left.displayOrder.compareTo(right.displayOrder);
      if (orderComparison != 0) {
        return orderComparison;
      }
      return left.name.compareTo(right.name);
    });
  }

  List<CompanyCatalogItem> get _filteredCatalogs {
    final normalizedQuery = _query.trim().toLowerCase();
    return widget.catalogs
        .where((catalog) {
          final matchesCategory =
              _selectedCategoryId == null ||
              catalog.catalogCategoryId == _selectedCategoryId;
          final matchesQuery =
              normalizedQuery.isEmpty ||
              catalog.name.toLowerCase().contains(normalizedQuery) ||
              (catalog.description?.toLowerCase().contains(normalizedQuery) ??
                  false);
          return matchesCategory && matchesQuery;
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final categories = _visibleCategories;
    final filteredCatalogs = _filteredCatalogs;

    return _Section(
      title: 'Catalogue',
      emptyMessage: 'Aucun element de catalogue disponible.',
      isEmpty: widget.catalogs.isEmpty,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: (value) => setState(() {
              _query = value;
            }),
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Rechercher dans le catalogue',
            ),
          ),
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _CatalogCategoryChip(
                    label: 'Tout',
                    selected: _selectedCategoryId == null,
                    onSelected: () => setState(() {
                      _selectedCategoryId = null;
                    }),
                  ),
                  for (final category in categories) ...[
                    const SizedBox(width: 8),
                    _CatalogCategoryChip(
                      label: category.name,
                      selected: _selectedCategoryId == category.id,
                      onSelected: () => setState(() {
                        _selectedCategoryId = category.id;
                      }),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (filteredCatalogs.isEmpty)
            const _StateBox(
              icon: Icons.search_off_outlined,
              title: 'Aucun article trouve',
              message: 'Essayez une autre recherche ou une autre categorie.',
            )
          else
            for (final catalog in filteredCatalogs) ...[
              _CatalogTile(catalog: catalog),
              if (catalog != filteredCatalogs.last) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _CatalogCategoryChip extends StatelessWidget {
  const _CatalogCategoryChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: FlowMovaColors.primaryAqua.withValues(alpha: 0.14),
      backgroundColor: FlowMovaColors.white,
      side: BorderSide(
        color: selected ? FlowMovaColors.primaryAqua : FlowMovaColors.border,
      ),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: selected ? FlowMovaColors.ink : FlowMovaColors.slate,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _CatalogTile extends StatelessWidget {
  const _CatalogTile({required this.catalog});

  final CompanyCatalogItem catalog;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CatalogThumb(catalog: catalog),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    catalog.name,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (catalog.description != null &&
                      catalog.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      catalog.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: FlowMovaColors.slate,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    catalog.priceLabel,
                    style: textTheme.labelLarge?.copyWith(
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

class _CatalogThumb extends StatelessWidget {
  const _CatalogThumb({required this.catalog});

  final CompanyCatalogItem catalog;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: FlowMovaColors.primaryAqua.withValues(alpha: 0.12),
      child: const Icon(Icons.local_offer_outlined),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(FlowMovaRadii.medium),
      child: SizedBox(
        width: 72,
        height: 72,
        child: catalog.imageUrl == null || catalog.imageUrl!.trim().isEmpty
            ? fallback
            : Image.network(
                catalog.imageUrl!.trim(),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.emptyMessage,
    required this.isEmpty,
    required this.child,
  });

  final String title;
  final String emptyMessage;
  final bool isEmpty;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        if (isEmpty)
          _StateBox(
            icon: Icons.info_outline,
            title: emptyMessage,
            message: 'Revenez plus tard ou contactez directement l entreprise.',
          )
        else
          child,
      ],
    );
  }
}

class _CompanyClosedNotice extends StatelessWidget {
  const _CompanyClosedNotice();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FlowMovaColors.error.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(FlowMovaRadii.medium),
        border: Border.all(color: FlowMovaColors.error.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline,
              size: 20,
              color: FlowMovaColors.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Cette entreprise n accepte pas de commandes pour le moment.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: FlowMovaColors.ink,
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

class _OperationalStatusPill extends StatelessWidget {
  const _OperationalStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isOpen = status == 'OPEN';
    final color = isOpen ? FlowMovaColors.leafGreen : FlowMovaColors.error;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(FlowMovaRadii.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          isOpen ? 'Ouvert' : 'Ferme',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FlowMovaColors.cloud,
        borderRadius: BorderRadius.circular(FlowMovaRadii.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: FlowMovaColors.slate),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: FlowMovaColors.ink,
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

class _StateBox extends StatelessWidget {
  const _StateBox({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: FlowMovaColors.white,
        border: Border.all(color: FlowMovaColors.border),
        borderRadius: BorderRadius.circular(FlowMovaRadii.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: FlowMovaColors.slate),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: textTheme.bodyMedium?.copyWith(
                      color: FlowMovaColors.slate,
                    ),
                  ),
                  if (action != null) ...[const SizedBox(height: 12), action!],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _businessTypeLabel(String type) {
  return switch (type) {
    'RESTAURANT' => 'Restauration',
    'HAIR_SALON' => 'Coiffure',
    'RETAIL' => 'Commerce',
    'HEALTHCARE' => 'Sante',
    'ADMINISTRATION' => 'Administration',
    'SERVICE' => 'Service',
    'OTHER' => 'Autre',
    _ => type,
  };
}

IconData _businessTypeIcon(String type) {
  return switch (type) {
    'RESTAURANT' => Icons.restaurant_outlined,
    'HAIR_SALON' => Icons.content_cut_outlined,
    'RETAIL' => Icons.shopping_bag_outlined,
    'HEALTHCARE' => Icons.local_hospital_outlined,
    'ADMINISTRATION' => Icons.account_balance_outlined,
    'SERVICE' => Icons.handshake_outlined,
    'OTHER' => Icons.more_horiz_outlined,
    _ => Icons.storefront_outlined,
  };
}

Color _businessTypeColor(String type) {
  return switch (type) {
    'RESTAURANT' => FlowMovaColors.softApricot,
    'HAIR_SALON' => FlowMovaColors.skyBlue,
    'RETAIL' => FlowMovaColors.leafGreen,
    'HEALTHCARE' => FlowMovaColors.error,
    'ADMINISTRATION' => FlowMovaColors.logoInk,
    'SERVICE' => FlowMovaColors.primaryAqua,
    'OTHER' => FlowMovaColors.slate,
    _ => FlowMovaColors.primaryAqua,
  };
}

class _DetailLoading extends StatelessWidget {
  const _DetailLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _StateBox(
            icon: Icons.wifi_off_outlined,
            title: 'Fiche indisponible',
            message: message,
            action: OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reessayer'),
            ),
          ),
        ),
      ),
    );
  }
}
