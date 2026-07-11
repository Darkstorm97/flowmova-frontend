import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/session/session_scope.dart';
import '../../../core/theme/flow_mova_colors.dart';
import '../../client/data/company_detail_gateway.dart';
import '../data/admin_service_units_gateway.dart';
import '../data/business_dashboard_gateway.dart';

class BusinessServiceUnitItemsArguments {
  const BusinessServiceUnitItemsArguments({
    required this.companyId,
    required this.serviceUnit,
  });

  final String companyId;
  final BusinessServiceUnit serviceUnit;
}

class BusinessServiceUnitItemsScreen extends StatefulWidget {
  const BusinessServiceUnitItemsScreen({
    super.key,
    required this.companyId,
    required this.serviceUnit,
    this.gateway,
    this.dashboardGateway,
  });

  final String companyId;
  final BusinessServiceUnit serviceUnit;
  final AdminServiceUnitsGateway? gateway;
  final BusinessDashboardGateway? dashboardGateway;

  @override
  State<BusinessServiceUnitItemsScreen> createState() =>
      _BusinessServiceUnitItemsScreenState();
}

class _BusinessServiceUnitItemsScreenState
    extends State<BusinessServiceUnitItemsScreen> {
  AdminServiceUnitsGateway? _gateway;
  BusinessDashboardGateway? _dashboardGateway;
  Future<_ItemsBundle>? _future;
  String _query = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.of(context);
    _gateway ??=
        widget.gateway ??
        BackendAdminServiceUnitsGateway(
          ApiClient(accessTokenProvider: session.currentAccessToken),
        );
    _dashboardGateway ??=
        widget.dashboardGateway ??
        BackendBusinessDashboardGateway(
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
        message: 'Connectez-vous pour gerer les articles de ce service.',
      );
    }

    return FutureBuilder<_ItemsBundle>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _StateCard(
            icon: Icons.hourglass_empty,
            title: 'Chargement des articles',
            message: 'Nous recuperons les articles du service.',
          );
        }
        if (snapshot.hasError) {
          return _StateCard(
            icon: Icons.error_outline,
            title: 'Articles indisponibles',
            message: _errorMessage(snapshot.error),
            actionLabel: 'Reessayer',
            onAction: _reload,
          );
        }

        final bundle = snapshot.requireData;
        final items = _filtered(bundle.items);
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                serviceName: widget.serviceUnit.name,
                count: bundle.items.length,
                onCreate: () => _openForm(bundle: bundle),
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Rechercher un article',
                ),
              ),
              const SizedBox(height: 14),
              if (items.isEmpty)
                const _StateCard(
                  icon: Icons.inventory_2_outlined,
                  title: 'Aucun article',
                  message:
                      'Associez un catalogue a ce service pour le rendre selectionnable dans les commandes.',
                )
              else
                for (final item in items) ...[
                  _ItemCard(
                    item: item,
                    onEdit: () => _openForm(item: item, bundle: bundle),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        );
      },
    );
  }

  Future<_ItemsBundle> _load() async {
    final items = await _gateway!.listItems(
      widget.companyId,
      widget.serviceUnit.id,
    );
    final dashboard = await _dashboardGateway!.getDashboard(widget.companyId);
    return _ItemsBundle(items: items, catalogs: dashboard.catalogs);
  }

  List<BusinessServiceUnitItem> _filtered(List<BusinessServiceUnitItem> items) {
    final needle = _query.trim().toLowerCase();
    if (needle.isEmpty) {
      return items;
    }
    return items
        .where(
          (item) =>
              item.catalog.name.toLowerCase().contains(needle) ||
              item.availability.toLowerCase().contains(needle) ||
              item.status.toLowerCase().contains(needle),
        )
        .toList(growable: false);
  }

  Future<void> _openForm({
    required _ItemsBundle bundle,
    BusinessServiceUnitItem? item,
  }) async {
    final usedCatalogIds = {
      for (final existing in bundle.items)
        if (item == null || existing.id != item.id) existing.catalog.id,
    };
    final input = await showModalBottomSheet<ServiceUnitItemInput>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ItemFormSheet(
        item: item,
        catalogs: bundle.catalogs
            .where(
              (catalog) => item != null || !usedCatalogIds.contains(catalog.id),
            )
            .toList(growable: false),
      ),
    );
    if (input == null) {
      return;
    }

    try {
      if (item == null) {
        await _gateway!.createItem(
          widget.companyId,
          widget.serviceUnit.id,
          input,
        );
      } else {
        await _gateway!.updateItem(
          widget.companyId,
          widget.serviceUnit.id,
          item.id,
          input,
        );
      }
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

  void _reload() {
    setState(() => _future = _load());
  }

  String _errorMessage(Object? error) {
    if (error is ApiException) {
      return error.message;
    }
    if (error is FormatException) {
      return 'Les donnees articles sont illisibles.';
    }
    return 'Impossible de charger les articles pour le moment.';
  }
}

class _ItemsBundle {
  const _ItemsBundle({required this.items, required this.catalogs});

  final List<BusinessServiceUnitItem> items;
  final List<CompanyCatalogItem> catalogs;
}

class _Header extends StatelessWidget {
  const _Header({
    required this.serviceName,
    required this.count,
    required this.onCreate,
  });

  final String serviceName;
  final int count;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                serviceName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$count article${count > 1 ? 's' : ''}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: FlowMovaColors.slate),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add),
          label: const Text('Nouveau'),
        ),
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.onEdit});

  final BusinessServiceUnitItem item;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
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
                    item.catalog.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _StatusPill(label: _availabilityLabel(item.availability)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Prix: ${item.priceLabel}'),
            const SizedBox(height: 4),
            Text(
              'Quantite: ${item.configuredQuantity?.toString() ?? 'non limitee'} - Reserve: ${item.reservedQuantity}',
              style: const TextStyle(color: FlowMovaColors.slate),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Modifier'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemFormSheet extends StatefulWidget {
  const _ItemFormSheet({required this.catalogs, this.item});

  final List<CompanyCatalogItem> catalogs;
  final BusinessServiceUnitItem? item;

  @override
  State<_ItemFormSheet> createState() => _ItemFormSheetState();
}

class _ItemFormSheetState extends State<_ItemFormSheet> {
  late String? _catalogId =
      widget.item?.catalog.id ??
      (widget.catalogs.isNotEmpty ? widget.catalogs.first.id : null);
  late String _availability = widget.item?.availability ?? 'AVAILABLE';
  late final TextEditingController _priceController = TextEditingController(
    text: widget.item?.priceAmount?.toString() ?? '',
  );
  late final TextEditingController _quantityController = TextEditingController(
    text: widget.item?.configuredQuantity?.toString() ?? '',
  );
  late final TextEditingController _orderController = TextEditingController(
    text: (widget.item?.displayOrder ?? 0).toString(),
  );
  final _catalogSearchController = TextEditingController();
  String _catalogQuery = '';

  @override
  Widget build(BuildContext context) {
    final editing = widget.item != null;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 18,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                editing ? 'Modifier article' : 'Nouvel article',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              if (!editing) ...[
                TextField(
                  controller: _catalogSearchController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Rechercher dans le catalogue',
                  ),
                  onChanged: (value) => setState(() {
                    _catalogQuery = value;
                    final visibleCatalogs = _filteredCatalogs();
                    if (_catalogId != null &&
                        !visibleCatalogs.any(
                          (catalog) => catalog.id == _catalogId,
                        )) {
                      _catalogId = visibleCatalogs.isEmpty
                          ? null
                          : visibleCatalogs.first.id;
                    }
                  }),
                ),
                const SizedBox(height: 10),
              ],
              if (_catalogOptions().isEmpty)
                const _StateCard(
                  icon: Icons.inventory_2_outlined,
                  title: 'Aucun catalogue',
                  message: 'Aucun catalogue disponible pour cette recherche.',
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: _catalogId,
                  decoration: const InputDecoration(labelText: 'Catalogue'),
                  items: [
                    for (final catalog in _catalogOptions())
                      DropdownMenuItem(
                        value: catalog.id,
                        child: Text(catalog.name),
                      ),
                  ],
                  onChanged: editing
                      ? null
                      : (value) => setState(() => _catalogId = value),
                ),
              const SizedBox(height: 10),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Prix optionnel',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _availability,
                decoration: const InputDecoration(labelText: 'Disponibilite'),
                items: const [
                  DropdownMenuItem(
                    value: 'AVAILABLE',
                    child: Text('Disponible'),
                  ),
                  DropdownMenuItem(
                    value: 'UNAVAILABLE',
                    child: Text('Indisponible'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _availability = value ?? _availability),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantite representative',
                  prefixIcon: Icon(Icons.numbers_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _orderController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Ordre affichage',
                  prefixIcon: Icon(Icons.sort_outlined),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(editing ? 'Enregistrer' : 'Creer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    final catalogId = _catalogId;
    if (catalogId == null || catalogId.trim().isEmpty) {
      return;
    }
    Navigator.pop(
      context,
      ServiceUnitItemInput(
        catalogId: catalogId,
        priceAmount: num.tryParse(_priceController.text.trim()),
        availability: _availability,
        configuredQuantity: int.tryParse(_quantityController.text.trim()),
        displayOrder: int.tryParse(_orderController.text.trim()) ?? 0,
      ),
    );
  }

  List<CompanyCatalogItem> _catalogOptions() {
    if (widget.item != null) {
      return [widget.item!.catalog];
    }
    return _filteredCatalogs();
  }

  List<CompanyCatalogItem> _filteredCatalogs() {
    final needle = _catalogQuery.trim().toLowerCase();
    if (needle.isEmpty) {
      return widget.catalogs;
    }
    return widget.catalogs
        .where(
          (catalog) =>
              catalog.name.toLowerCase().contains(needle) ||
              (catalog.description?.toLowerCase().contains(needle) ?? false),
        )
        .toList(growable: false);
  }

  @override
  void dispose() {
    _priceController.dispose();
    _quantityController.dispose();
    _orderController.dispose();
    _catalogSearchController.dispose();
    super.dispose();
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

String _availabilityLabel(String availability) {
  return switch (availability) {
    'AVAILABLE' => 'Disponible',
    'UNAVAILABLE' => 'Indisponible',
    _ => availability,
  };
}
