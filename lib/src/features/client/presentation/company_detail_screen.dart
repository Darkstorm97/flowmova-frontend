import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/session/session_scope.dart';
import '../../../core/theme/flow_mova_colors.dart';
import '../../../core/theme/flow_mova_radii.dart';
import '../../../shared/widgets/flow_mova_app_bar_title.dart';
import '../../tickets/data/ticket_creation_gateway.dart';
import '../data/company_detail_gateway.dart';

class CompanyDetailScreen extends StatefulWidget {
  const CompanyDetailScreen({
    required this.companyId,
    super.key,
    this.detailGateway,
    this.ticketCreationGateway,
  });

  final String companyId;
  final CompanyDetailGateway? detailGateway;
  final TicketCreationGateway? ticketCreationGateway;

  @override
  State<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<CompanyDetailScreen> {
  late final CompanyDetailGateway _detailGateway =
      widget.detailGateway ?? BackendCompanyDetailGateway(ApiClient());

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
  });

  final CompanyDetailBundle bundle;
  final CompanyDetailGateway detailGateway;
  final TicketCreationGateway ticketCreationGateway;

  @override
  Widget build(BuildContext context) {
    final company = bundle.company;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CompanyHero(company: company),
        const SizedBox(height: 16),
        _QuickActions(
          bundle: bundle,
          detailGateway: detailGateway,
          ticketCreationGateway: ticketCreationGateway,
        ),
        const SizedBox(height: 18),
        _ServiceUnitsSection(serviceUnits: bundle.serviceUnits),
        const SizedBox(height: 18),
        _CatalogSection(catalogs: bundle.catalogs),
      ],
    );
  }
}

class _CompanyHero extends StatelessWidget {
  const _CompanyHero({required this.company});

  final CompanyDetail company;

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
                    _StatusPill(status: company.status),
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
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.map_outlined, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(company.addressLabel)),
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

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.bundle,
    required this.detailGateway,
    required this.ticketCreationGateway,
  });

  final CompanyDetailBundle bundle;
  final CompanyDetailGateway detailGateway;
  final TicketCreationGateway ticketCreationGateway;

  @override
  Widget build(BuildContext context) {
    final hasService = bundle.serviceUnits.isNotEmpty;

    return FilledButton.icon(
      onPressed: hasService
          ? () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => _CreateTicketSheet(
                bundle: bundle,
                detailGateway: detailGateway,
                ticketCreationGateway: ticketCreationGateway,
              ),
            )
          : null,
      icon: const Icon(Icons.add_task_outlined),
      label: Text(hasService ? 'Creer une demande' : 'Aucun service ouvert'),
    );
  }
}

class _CreateTicketSheet extends StatefulWidget {
  const _CreateTicketSheet({
    required this.bundle,
    required this.detailGateway,
    required this.ticketCreationGateway,
  });

  final CompanyDetailBundle bundle;
  final CompanyDetailGateway detailGateway;
  final TicketCreationGateway ticketCreationGateway;

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
  TicketCreationResult? _createdTicket;
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
                  : _TicketCreatedSummary(ticket: _createdTicket!),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
          'Creer une demande',
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
        _ServicePicker(
          serviceUnits: widget.bundle.serviceUnits,
          selectedServiceUnit: _selectedServiceUnit,
          onSelected: _selectServiceUnit,
        ),
        const SizedBox(height: 16),
        if (_loadingServiceUnit)
          const Center(child: CircularProgressIndicator())
        else if (_serviceUnitDetail != null) ...[
          _LocationPicker(
            locations: _serviceUnitDetail!.locations,
            selectedLocation: _selectedLocation,
            onSelected: (location) => setState(() {
              _selectedLocation = location;
            }),
          ),
          const SizedBox(height: 16),
          _ItemsPicker(
            items: _serviceUnitDetail!.items,
            selectedItemIds: _selectedItemIds,
            itemQuantities: _itemQuantities,
            onToggle: _toggleItem,
            onQuantityChanged: _setItemQuantity,
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

  void _toggleItem(CompanyServiceUnitAvailableItem item, bool selected) {
    setState(() {
      if (selected) {
        _selectedItemIds.add(item.id);
        _itemQuantities[item.id] = _itemQuantities[item.id] ?? 1;
      } else {
        _selectedItemIds.remove(item.id);
        _itemQuantities.remove(item.id);
      }
    });
  }

  void _setItemQuantity(CompanyServiceUnitAvailableItem item, int quantity) {
    setState(() {
      _itemQuantities[item.id] = quantity.clamp(1, 99);
    });
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

      if (mounted) {
        setState(() => _createdTicket = result);
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

  @override
  void dispose() {
    _guestNameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

class _ServicePicker extends StatelessWidget {
  const _ServicePicker({
    required this.serviceUnits,
    required this.selectedServiceUnit,
    required this.onSelected,
  });

  final List<CompanyServiceUnitItem> serviceUnits;
  final CompanyServiceUnitItem? selectedServiceUnit;
  final ValueChanged<CompanyServiceUnitItem> onSelected;

  @override
  Widget build(BuildContext context) {
    if (serviceUnits.length == 1) {
      return _SelectedSummary(
        icon: Icons.room_service_outlined,
        label: 'Service',
        value: serviceUnits.single.name,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choisir un service',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        for (final serviceUnit in serviceUnits) ...[
          _SelectableTile(
            selected: selectedServiceUnit?.id == serviceUnit.id,
            icon: Icons.room_service_outlined,
            title: serviceUnit.name,
            subtitle: serviceUnit.location,
            onTap: () => onSelected(serviceUnit),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _LocationPicker extends StatelessWidget {
  const _LocationPicker({
    required this.locations,
    required this.selectedLocation,
    required this.onSelected,
  });

  final List<CompanyServiceUnitLocation> locations;
  final CompanyServiceUnitLocation? selectedLocation;
  final ValueChanged<CompanyServiceUnitLocation> onSelected;

  @override
  Widget build(BuildContext context) {
    if (locations.isEmpty) {
      return const _StateBox(
        icon: Icons.place_outlined,
        title: 'Aucun emplacement disponible',
        message: 'Ce service ne peut pas encore recevoir de demande.',
      );
    }

    if (locations.length == 1) {
      return _SelectedSummary(
        icon: Icons.place_outlined,
        label: 'Emplacement',
        value: locations.single.name,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choisir un emplacement',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        for (final location in locations) ...[
          _SelectableTile(
            selected: selectedLocation?.id == location.id,
            icon: Icons.place_outlined,
            title: location.name,
            subtitle: location.defaultLocation
                ? 'Emplacement par defaut'
                : location.type,
            onTap: () => onSelected(location),
          ),
          const SizedBox(height: 8),
        ],
      ],
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

class _ItemsPicker extends StatelessWidget {
  const _ItemsPicker({
    required this.items,
    required this.selectedItemIds,
    required this.itemQuantities,
    required this.onToggle,
    required this.onQuantityChanged,
  });

  final List<CompanyServiceUnitAvailableItem> items;
  final Set<String> selectedItemIds;
  final Map<String, int> itemQuantities;
  final void Function(CompanyServiceUnitAvailableItem item, bool selected)
  onToggle;
  final void Function(CompanyServiceUnitAvailableItem item, int quantity)
  onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Articles optionnels',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        for (final item in items)
          CheckboxListTile(
            value: selectedItemIds.contains(item.id),
            onChanged: (selected) => onToggle(item, selected ?? false),
            title: Text(item.catalog.name),
            subtitle: Text(item.priceLabel),
            secondary: selectedItemIds.contains(item.id)
                ? SizedBox(
                    width: 84,
                    child: DropdownButton<int>(
                      value: itemQuantities[item.id] ?? 1,
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
                          onQuantityChanged(item, quantity);
                        }
                      },
                    ),
                  )
                : null,
          ),
      ],
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

class _TicketCreatedSummary extends StatelessWidget {
  const _TicketCreatedSummary({required this.ticket});

  final TicketCreationResult ticket;

  @override
  Widget build(BuildContext context) {
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

class _ServiceUnitsSection extends StatelessWidget {
  const _ServiceUnitsSection({required this.serviceUnits});

  final List<CompanyServiceUnitItem> serviceUnits;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Services disponibles',
      emptyMessage: 'Aucun service ouvert pour le moment.',
      isEmpty: serviceUnits.isEmpty,
      child: Column(
        children: [
          for (final serviceUnit in serviceUnits) ...[
            _ServiceUnitTile(serviceUnit: serviceUnit),
            if (serviceUnit != serviceUnits.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ServiceUnitTile extends StatelessWidget {
  const _ServiceUnitTile({required this.serviceUnit});

  final CompanyServiceUnitItem serviceUnit;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.room_service_outlined),
        title: Text(serviceUnit.name),
        subtitle: Text(
          [
            if (serviceUnit.location != null &&
                serviceUnit.location!.trim().isNotEmpty)
              serviceUnit.location!,
            serviceUnit.status,
          ].join(' • '),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.pushNamed(context, AppRoutes.serviceUnitDetail),
      ),
    );
  }
}

class _CatalogSection extends StatelessWidget {
  const _CatalogSection({required this.catalogs});

  final List<CompanyCatalogItem> catalogs;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Catalogue',
      emptyMessage: 'Aucun element de catalogue disponible.',
      isEmpty: catalogs.isEmpty,
      child: Column(
        children: [
          for (final catalog in catalogs) ...[
            _CatalogTile(catalog: catalog),
            if (catalog != catalogs.last) const SizedBox(height: 10),
          ],
        ],
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FlowMovaColors.leafGreen.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(FlowMovaRadii.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          status == 'ACTIVE' ? 'Active' : status,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: FlowMovaColors.leafGreen,
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
