import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/session/session_scope.dart';
import '../../../core/theme/flow_mova_colors.dart';
import '../../client/data/company_detail_gateway.dart';
import '../data/admin_catalog_gateway.dart';
import 'company_image_picker.dart';

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
  final _searchController = TextEditingController();
  AdminCatalogGateway? _gateway;
  Future<AdminCatalogBundle>? _future;
  AdminCatalogBundle? _bundle;
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
    _future ??= _loadCatalog();
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

        final bundle = _bundle ?? snapshot.requireData;
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
              if (_selectedCategory(bundle.categories)
                  case final category?) ...[
                const SizedBox(height: 10),
                _SelectedCategoryActions(
                  category: category,
                  onEdit: () => _openCategoryForm(category: category),
                  onArchive: () => _archiveCategory(category),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
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
    final needle = _searchController.text.trim().toLowerCase();
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

  CompanyCatalogCategory? _selectedCategory(
    List<CompanyCatalogCategory> categories,
  ) {
    final selectedId = _categoryId;
    if (selectedId == null) {
      return null;
    }
    for (final category in categories) {
      if (category.id == selectedId) {
        return category;
      }
    }
    return null;
  }

  Future<void> _openCategoryForm({CompanyCatalogCategory? category}) async {
    final input = await showModalBottomSheet<CatalogCategoryInput>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CategoryFormSheet(category: category),
    );
    if (input == null) {
      return;
    }
    await _runMutation(
      () async {
        if (category == null) {
          return _gateway!.createCategory(widget.companyId, input);
        }
        return _gateway!.updateCategory(widget.companyId, category.id, input);
      },
      successMessage: category == null
          ? 'Categorie creee'
          : 'Categorie mise a jour',
    );
  }

  Future<void> _openCatalogForm({
    required AdminCatalogBundle bundle,
    CompanyCatalogItem? catalog,
  }) async {
    final result = await showModalBottomSheet<CatalogFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          _CatalogFormSheet(categories: bundle.categories, catalog: catalog),
    );
    if (result == null) {
      return;
    }
    await _runMutation(
      () async {
        if (catalog == null) {
          return _createCatalogWithOptionalImage(result);
        }
        return _updateCatalogWithOptionalImage(catalog.id, result);
      },
      successMessage: catalog == null
          ? 'Catalogue cree'
          : 'Catalogue mis a jour',
    );
  }

  Future<CompanyCatalogItem> _createCatalogWithOptionalImage(
    CatalogFormResult result,
  ) async {
    final created = await _gateway!.createCatalog(
      widget.companyId,
      result.input,
    );
    final image = result.image;
    if (image == null) {
      return created;
    }
    return _gateway!.uploadCatalogImage(widget.companyId, created.id, image);
  }

  Future<CompanyCatalogItem> _updateCatalogWithOptionalImage(
    String catalogId,
    CatalogFormResult result,
  ) async {
    final updated = await _gateway!.updateCatalog(
      widget.companyId,
      catalogId,
      result.input,
    );
    final image = result.image;
    if (image == null) {
      return updated;
    }
    return _gateway!.uploadCatalogImage(widget.companyId, catalogId, image);
  }

  Future<void> _archiveCategory(CompanyCatalogCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archiver cette categorie ?'),
        content: Text(category.name),
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
      await _runMutation(() async {
        final archived = await _gateway!.archiveCategory(
          widget.companyId,
          category.id,
        );
        if (_categoryId == category.id) {
          _categoryId = null;
        }
        return archived;
      }, successMessage: 'Categorie archivee');
    }
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
      await _runMutation(() async {
        return _gateway!.archiveCatalog(widget.companyId, catalog.id);
      }, successMessage: 'Catalogue archive');
    }
  }

  Future<void> _runMutation(
    Future<Object?> Function() action, {
    required String successMessage,
  }) async {
    try {
      final result = await action();
      _applyMutationResult(result);
      _showMessage(successMessage);
      unawaited(_refreshAfterMutation());
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    }
  }

  Future<AdminCatalogBundle> _loadCatalog() async {
    final bundle = await _gateway!.getCatalog(widget.companyId);
    _bundle = bundle;
    return bundle;
  }

  Future<void> _refreshAfterMutation() async {
    try {
      final bundle = await _gateway!.getCatalog(widget.companyId);
      if (mounted) {
        setState(() {
          _bundle = bundle;
          _future = Future.value(bundle);
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Element enregistre. Actualisez la page pour voir la liste a jour.',
          ),
        ),
      );
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _applyMutationResult(Object? result) {
    switch (result) {
      case CompanyCatalogCategory category:
        _applyCategoryMutation(category);
      case CompanyCatalogItem catalog:
        _applyCatalogMutation(catalog);
    }
  }

  void _applyCategoryMutation(CompanyCatalogCategory category) {
    final current = _bundle;
    if (current == null) {
      return;
    }

    final categories = current.categories
        .where((item) => item.id != category.id)
        .toList();
    final catalogs = current.catalogs.toList();

    if (category.status == 'ARCHIVED') {
      if (_categoryId == category.id) {
        _categoryId = null;
      }
      catalogs.removeWhere(
        (catalog) => catalog.catalogCategoryId == category.id,
      );
    } else {
      categories.add(category);
      categories.sort((a, b) {
        final orderComparison = a.displayOrder.compareTo(b.displayOrder);
        if (orderComparison != 0) {
          return orderComparison;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    }

    _setLocalBundle(
      AdminCatalogBundle(categories: categories, catalogs: catalogs),
    );
  }

  void _applyCatalogMutation(CompanyCatalogItem catalog) {
    final current = _bundle;
    if (current == null) {
      return;
    }

    final catalogs = current.catalogs
        .where((item) => item.id != catalog.id)
        .toList();
    if (catalog.status != 'ARCHIVED') {
      catalogs.add(catalog);
      catalogs.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    }

    _setLocalBundle(
      AdminCatalogBundle(categories: current.categories, catalogs: catalogs),
    );
  }

  void _setLocalBundle(AdminCatalogBundle bundle) {
    if (!mounted) {
      return;
    }
    setState(() {
      _bundle = bundle;
      _future = Future.value(bundle);
    });
  }

  void _reload() {
    setState(() => _future = _loadCatalog());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

class _SelectedCategoryActions extends StatelessWidget {
  const _SelectedCategoryActions({
    required this.category,
    required this.onEdit,
    required this.onArchive,
  });

  final CompanyCatalogCategory category;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: FlowMovaColors.cloud,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            tooltip: 'Modifier categorie',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Archiver categorie',
            onPressed: onArchive,
            icon: const Icon(Icons.archive_outlined),
          ),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CatalogImagePreview(
              imageUrl: catalog.imageUrl,
              width: 82,
              height: 82,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    catalog.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
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
          ],
        ),
      ),
    );
  }
}

class _CatalogImagePreview extends StatelessWidget {
  const _CatalogImagePreview({
    this.selectedImage,
    this.imageUrl,
    this.width,
    this.height,
  });

  final _SelectedCatalogImage? selectedImage;
  final String? imageUrl;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final selected = selectedImage;
    final normalizedImageUrl = _absoluteImageUrl(imageUrl);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: width ?? double.infinity,
        height: height ?? 140,
        child: selected != null
            ? Image.memory(selected.bytes, fit: BoxFit.cover)
            : normalizedImageUrl == null
            ? const _CatalogImageFallback()
            : Image.network(
                normalizedImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _CatalogImageFallback(),
              ),
      ),
    );
  }
}

class _CatalogImageFallback extends StatelessWidget {
  const _CatalogImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FlowMovaColors.cloud,
      alignment: Alignment.center,
      child: const Icon(
        Icons.inventory_2_outlined,
        color: FlowMovaColors.primaryAqua,
      ),
    );
  }
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

class CatalogFormResult {
  const CatalogFormResult({required this.input, this.image});

  final CatalogInput input;
  final CatalogImageUpload? image;
}

class _SelectedCatalogImage {
  const _SelectedCatalogImage({
    required this.bytes,
    required this.filename,
    required this.contentType,
  });

  final Uint8List bytes;
  final String filename;
  final String contentType;

  CatalogImageUpload toUpload() {
    return CatalogImageUpload(
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );
  }
}

class _CategoryFormSheet extends StatefulWidget {
  const _CategoryFormSheet({this.category});

  final CompanyCatalogCategory? category;

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  late final _nameController = TextEditingController(
    text: widget.category?.name ?? '',
  );
  late final _descriptionController = TextEditingController(
    text: widget.category?.description ?? '',
  );
  late final _displayOrderController = TextEditingController(
    text: (widget.category?.displayOrder ?? 0).toString(),
  );

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: widget.category == null
          ? 'Nouvelle categorie'
          : 'Modifier categorie',
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
  late final _priceController = TextEditingController(
    text: widget.catalog?.priceAmount?.toString() ?? '',
  );
  _SelectedCatalogImage? _selectedImage;

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: widget.catalog == null
          ? 'Nouveau catalogue'
          : 'Modifier catalogue',
      children: [
        _CatalogImagePreview(
          selectedImage: _selectedImage,
          imageUrl: widget.catalog?.imageUrl,
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.photo_library_outlined),
          label: Text(_selectedImage == null ? 'Choisir image' : 'Remplacer'),
        ),
        if (_selectedImage != null) ...[
          const SizedBox(height: 6),
          Text(
            _selectedImage!.filename,
            style: const TextStyle(color: FlowMovaColors.slate),
          ),
        ],
        const SizedBox(height: 12),
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
          controller: _priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Prix indicatif'),
        ),
      ],
      onSubmit: () => Navigator.pop(
        context,
        CatalogFormResult(
          input: CatalogInput(
            catalogCategoryId: _categoryId,
            name: _nameController.text,
            description: _descriptionController.text,
            imageUrl: widget.catalog?.imageUrl,
            priceAmount: num.tryParse(_priceController.text.trim()),
          ),
          image: _selectedImage?.toUpload(),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final result = await pickCompanyImage(
        context,
        profile: CompanyImagePickProfile.catalog,
      );
      if (result == null || !mounted) {
        return;
      }
      setState(() {
        _selectedImage = _SelectedCatalogImage(
          bytes: result.bytes,
          filename: result.filename,
          contentType: result.contentType,
        );
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de lire cette image.')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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
