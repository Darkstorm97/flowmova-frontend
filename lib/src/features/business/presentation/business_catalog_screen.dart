import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/session/session_scope.dart';
import '../../../core/theme/flow_mova_colors.dart';
import '../../client/data/company_detail_gateway.dart';
import '../data/admin_catalog_gateway.dart';

class BusinessCatalogScreen extends StatefulWidget {
  const BusinessCatalogScreen({
    super.key,
    required this.companyId,
    this.gateway,
  });

  final String companyId;
  final AdminCatalogGateway? gateway;

  @override
  State<BusinessCatalogScreen> createState() => _BusinessCatalogScreenState();
}

class _BusinessCatalogScreenState extends State<BusinessCatalogScreen> {
  AdminCatalogGateway? _gateway;
  Future<AdminCatalogBundle>? _future;
  String _query = '';
  String? _categoryId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.of(context);
    _gateway ??=
        widget.gateway ??
        BackendAdminCatalogGateway(
          ApiClient(accessTokenProvider: session.currentAccessToken),
        );
    _future ??= _gateway!.getCatalog(widget.companyId);
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    if (!session.isAuthenticated) {
      return const _StateCard(
        icon: Icons.lock_outline,
        title: 'Connexion requise',
        message: 'Connectez-vous pour gerer le catalogue.',
      );
    }

    return FutureBuilder<AdminCatalogBundle>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _StateCard(
            icon: Icons.hourglass_empty,
            title: 'Chargement du catalogue',
            message: 'Nous recuperons les categories et les catalogues.',
          );
        }
        if (snapshot.hasError) {
          return _StateCard(
            icon: Icons.error_outline,
            title: 'Catalogue indisponible',
            message: _errorMessage(snapshot.error),
            actionLabel: 'Reessayer',
            onAction: _reload,
          );
        }

        final bundle = snapshot.requireData;
        final catalogs = _filteredCatalogs(bundle.catalogs);
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                categoryCount: bundle.categories.length,
                catalogCount: bundle.catalogs.length,
                onCreateCategory: _openCategoryForm,
                onCreateCatalog: bundle.categories.isEmpty
                    ? null
                    : () => _openCatalogForm(bundle: bundle),
              ),
              const SizedBox(height: 14),
              _CategoryRail(
                categories: bundle.categories,
                selectedCategoryId: _categoryId,
                onSelected: (value) => setState(() => _categoryId = value),
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Rechercher dans le catalogue',
                ),
              ),
              const SizedBox(height: 14),
              if (bundle.categories.isEmpty)
                const _StateCard(
                  icon: Icons.category_outlined,
                  title: 'Creez une categorie',
                  message:
                      'Les catalogues doivent etre classes dans une categorie.',
                )
              else if (catalogs.isEmpty)
                const _StateCard(
                  icon: Icons.inventory_2_outlined,
                  title: 'Aucun catalogue',
                  message:
                      'Ajoutez un premier element de catalogue pour alimenter les articles des services.',
                )
              else
                for (final catalog in catalogs) ...[
                  _CatalogCard(
                    catalog: catalog,
                    categories: bundle.categories,
                    onEdit: () =>
                        _openCatalogForm(bundle: bundle, catalog: catalog),
                    onArchive: () => _archiveCatalog(catalog),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        );
      },
    );
  }

  List<CompanyCatalogItem> _filteredCatalogs(
    List<CompanyCatalogItem> catalogs,
  ) {
    final needle = _query.trim().toLowerCase();
    return catalogs
        .where((catalog) {
          final categoryMatches =
              _categoryId == null || catalog.catalogCategoryId == _categoryId;
          final queryMatches =
              needle.isEmpty ||
              catalog.name.toLowerCase().contains(needle) ||
              (catalog.description?.toLowerCase().contains(needle) ?? false);
          return categoryMatches && queryMatches;
        })
        .toList(growable: false);
  }

  Future<void> _openCategoryForm() async {
    final input = await showModalBottomSheet<CatalogCategoryInput>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _CategoryFormSheet(),
    );
    if (input == null) {
      return;
    }
    await _runMutation(() => _gateway!.createCategory(widget.companyId, input));
  }

  Future<void> _openCatalogForm({
    required AdminCatalogBundle bundle,
    CompanyCatalogItem? catalog,
  }) async {
    final input = await showModalBottomSheet<CatalogInput>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          _CatalogFormSheet(categories: bundle.categories, catalog: catalog),
    );
    if (input == null) {
      return;
    }
    await _runMutation(() {
      if (catalog == null) {
        return _gateway!.createCatalog(widget.companyId, input);
      }
      return _gateway!.updateCatalog(widget.companyId, catalog.id, input);
    });
  }

  Future<void> _archiveCatalog(CompanyCatalogItem catalog) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archiver ce catalogue ?'),
        content: Text(catalog.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archiver'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _runMutation(
        () => _gateway!.archiveCatalog(widget.companyId, catalog.id),
      );
    }
  }

  Future<void> _runMutation(Future<Object?> Function() action) async {
    try {
      await action();
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
    setState(() => _future = _gateway!.getCatalog(widget.companyId));
  }

  String _errorMessage(Object? error) {
    if (error is ApiException) {
      return error.message;
    }
    if (error is FormatException) {
      return 'Les donnees catalogue sont illisibles.';
    }
    return 'Impossible de charger le catalogue pour le moment.';
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.categoryCount,
    required this.catalogCount,
    required this.onCreateCategory,
    required this.onCreateCatalog,
  });

  final int categoryCount;
  final int catalogCount;
  final VoidCallback onCreateCategory;
  final VoidCallback? onCreateCatalog;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catalogue',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          '$catalogCount catalogue${catalogCount > 1 ? 's' : ''} - $categoryCount categorie${categoryCount > 1 ? 's' : ''}',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: FlowMovaColors.slate),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: onCreateCatalog,
              icon: const Icon(Icons.add),
              label: const Text('Catalogue'),
            ),
            OutlinedButton.icon(
              onPressed: onCreateCategory,
              icon: const Icon(Icons.category_outlined),
              label: const Text('Categorie'),
            ),
          ],
        ),
      ],
    );
  }
}

class _CategoryRail extends StatelessWidget {
  const _CategoryRail({
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  final List<CompanyCatalogCategory> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Tout'),
            selected: selectedCategoryId == null,
            onSelected: (_) => onSelected(null),
          ),
          const SizedBox(width: 8),
          for (final category in categories) ...[
            ChoiceChip(
              label: Text(category.name),
              selected: selectedCategoryId == category.id,
              onSelected: (_) => onSelected(category.id),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({
    required this.catalog,
    required this.categories,
    required this.onEdit,
    required this.onArchive,
  });

  final CompanyCatalogItem catalog;
  final List<CompanyCatalogCategory> categories;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    String? categoryName;
    for (final category in categories) {
      if (category.id == catalog.catalogCategoryId) {
        categoryName = category.name;
        break;
      }
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              catalog.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              [?categoryName, catalog.priceLabel].join(' - '),
              style: const TextStyle(color: FlowMovaColors.slate),
            ),
            if (catalog.description != null &&
                catalog.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(catalog.description!),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Modifier'),
                ),
                TextButton.icon(
                  onPressed: onArchive,
                  icon: const Icon(Icons.archive_outlined),
                  label: const Text('Archiver'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFormSheet extends StatefulWidget {
  const _CategoryFormSheet();

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _displayOrderController = TextEditingController(text: '0');

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Nouvelle categorie',
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Nom'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(labelText: 'Description'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _displayOrderController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Ordre affichage'),
        ),
      ],
      onSubmit: () => Navigator.pop(
        context,
        CatalogCategoryInput(
          name: _nameController.text,
          description: _descriptionController.text,
          displayOrder: int.tryParse(_displayOrderController.text.trim()),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _displayOrderController.dispose();
    super.dispose();
  }
}

class _CatalogFormSheet extends StatefulWidget {
  const _CatalogFormSheet({required this.categories, this.catalog});

  final List<CompanyCatalogCategory> categories;
  final CompanyCatalogItem? catalog;

  @override
  State<_CatalogFormSheet> createState() => _CatalogFormSheetState();
}

class _CatalogFormSheetState extends State<_CatalogFormSheet> {
  late String _categoryId =
      widget.catalog?.catalogCategoryId ?? widget.categories.first.id;
  late final _nameController = TextEditingController(
    text: widget.catalog?.name ?? '',
  );
  late final _descriptionController = TextEditingController(
    text: widget.catalog?.description ?? '',
  );
  late final _imageUrlController = TextEditingController(
    text: widget.catalog?.imageUrl ?? '',
  );
  late final _priceController = TextEditingController(
    text: widget.catalog?.priceAmount?.toString() ?? '',
  );

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: widget.catalog == null
          ? 'Nouveau catalogue'
          : 'Modifier catalogue',
      children: [
        DropdownButtonFormField<String>(
          initialValue: _categoryId,
          decoration: const InputDecoration(labelText: 'Categorie'),
          items: [
            for (final category in widget.categories)
              DropdownMenuItem(value: category.id, child: Text(category.name)),
          ],
          onChanged: (value) =>
              setState(() => _categoryId = value ?? _categoryId),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Nom'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(labelText: 'Description'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _imageUrlController,
          decoration: const InputDecoration(labelText: 'URL image'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Prix indicatif'),
        ),
      ],
      onSubmit: () => Navigator.pop(
        context,
        CatalogInput(
          catalogCategoryId: _categoryId,
          name: _nameController.text,
          description: _descriptionController.text,
          imageUrl: _imageUrlController.text,
          priceAmount: num.tryParse(_priceController.text.trim()),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({
    required this.title,
    required this.children,
    required this.onSubmit,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
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
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              ...children,
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onSubmit,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
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
