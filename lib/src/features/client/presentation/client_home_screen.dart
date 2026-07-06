import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/theme/flow_mova_colors.dart';
import '../../../core/theme/flow_mova_radii.dart';
import '../data/company_search_gateway.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key, this.searchGateway});

  final CompanySearchGateway? searchGateway;

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  static const _pageSize = 10;

  final _searchController = TextEditingController();
  final _cityController = TextEditingController();
  final _regionController = TextEditingController();
  final _countryController = TextEditingController();

  late final CompanySearchGateway _searchGateway =
      widget.searchGateway ?? BackendCompanySearchGateway(ApiClient());

  CompanySearchPage? _results;
  String? _selectedBusinessType;
  String? _errorMessage;
  bool _loading = false;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trouvez une entreprise',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Recherchez par nom, domaine ou localisation, puis ouvrez la fiche publique pour consulter les services disponibles.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: FlowMovaColors.slate,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filledTonal(
              tooltip: 'Scanner un QR code',
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.publicLocationDetail),
              icon: const Icon(Icons.qr_code_scanner_outlined),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SearchPanel(
          searchController: _searchController,
          cityController: _cityController,
          regionController: _regionController,
          countryController: _countryController,
          selectedBusinessType: _selectedBusinessType,
          loading: _loading,
          onBusinessTypeChanged: (value) {
            setState(() => _selectedBusinessType = value);
          },
          onSubmit: () => _search(page: 0),
          onReset: _resetFilters,
        ),
        const SizedBox(height: 18),
        _ResultsHeader(results: _results, loading: _loading),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _buildResults(context),
        ),
      ],
    );
  }

  Widget _buildResults(BuildContext context) {
    if (_loading && _results == null) {
      return const _LoadingResults();
    }

    if (_errorMessage != null) {
      return _ErrorResults(message: _errorMessage!, onRetry: () => _search());
    }

    final results = _results;
    if (results == null) {
      return const SizedBox.shrink();
    }

    if (results.items.isEmpty) {
      return const _EmptyResults();
    }

    return Column(
      key: ValueKey('companies-page-${results.page}'),
      children: [
        for (final company in results.items) ...[
          _CompanyResultCard(company: company),
          const SizedBox(height: 10),
        ],
        _PaginationBar(
          results: results,
          loading: _loading,
          onPrevious: () => _search(page: results.page - 1),
          onNext: () => _search(page: results.page + 1),
        ),
      ],
    );
  }

  Future<void> _search({int? page}) async {
    final nextPage = page ?? _page;
    setState(() {
      _loading = true;
      _errorMessage = null;
      _page = nextPage;
    });

    try {
      final results = await _searchGateway.search(
        CompanySearchQuery(
          text: _searchController.text,
          businessType: _selectedBusinessType,
          city: _cityController.text,
          region: _regionController.text,
          country: _countryController.text,
          page: nextPage,
          size: _pageSize,
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _results = results;
        _page = results.page;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = error.message);
    } on FormatException {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = 'La liste des entreprises est illisible.');
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = 'Impossible de charger les entreprises.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _resetFilters() {
    _searchController.clear();
    _cityController.clear();
    _regionController.clear();
    _countryController.clear();
    setState(() => _selectedBusinessType = null);
    _search(page: 0);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cityController.dispose();
    _regionController.dispose();
    _countryController.dispose();
    super.dispose();
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
    required this.searchController,
    required this.cityController,
    required this.regionController,
    required this.countryController,
    required this.selectedBusinessType,
    required this.loading,
    required this.onBusinessTypeChanged,
    required this.onSubmit,
    required this.onReset,
  });

  final TextEditingController searchController;
  final TextEditingController cityController;
  final TextEditingController regionController;
  final TextEditingController countryController;
  final String? selectedBusinessType;
  final bool loading;
  final ValueChanged<String?> onBusinessTypeChanged;
  final VoidCallback onSubmit;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSubmit(),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_outlined),
                labelText: 'Recherche',
                hintText: 'Nom, service ou mot cle',
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 620;
                final fields = [
                  _BusinessTypeField(
                    value: selectedBusinessType,
                    onChanged: onBusinessTypeChanged,
                  ),
                  _FilterTextField(
                    controller: cityController,
                    label: 'Ville',
                    icon: Icons.location_city_outlined,
                  ),
                  _FilterTextField(
                    controller: regionController,
                    label: 'Region',
                    icon: Icons.map_outlined,
                  ),
                  _FilterTextField(
                    controller: countryController,
                    label: 'Pays',
                    icon: Icons.flag_outlined,
                    textCapitalization: TextCapitalization.characters,
                  ),
                ];

                if (compact) {
                  return Column(
                    children: [
                      for (final field in fields) ...[
                        field,
                        const SizedBox(height: 10),
                      ],
                    ],
                  );
                }

                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final field in fields)
                      SizedBox(
                        width: (constraints.maxWidth - 10) / 2,
                        child: field,
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: loading ? null : onSubmit,
                    icon: const Icon(Icons.search),
                    label: const Text('Rechercher'),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.outlined(
                  tooltip: 'Reinitialiser les filtres',
                  onPressed: loading ? null : onReset,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BusinessTypeField extends StatelessWidget {
  const _BusinessTypeField({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.category_outlined),
        labelText: 'Domaine',
      ),
      items: const [
        DropdownMenuItem(value: null, child: Text('Tous les domaines')),
        DropdownMenuItem(value: 'RESTAURANT', child: Text('Restauration')),
        DropdownMenuItem(value: 'HAIR_SALON', child: Text('Salon de coiffure')),
        DropdownMenuItem(value: 'RETAIL', child: Text('Commerce')),
        DropdownMenuItem(value: 'HEALTHCARE', child: Text('Sante')),
        DropdownMenuItem(
          value: 'ADMINISTRATION',
          child: Text('Administration'),
        ),
        DropdownMenuItem(value: 'SERVICE', child: Text('Service')),
        DropdownMenuItem(value: 'OTHER', child: Text('Autre')),
      ],
      onChanged: onChanged,
    );
  }
}

class _FilterTextField extends StatelessWidget {
  const _FilterTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.textCapitalization = TextCapitalization.words,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(prefixIcon: Icon(icon), labelText: label),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({required this.results, required this.loading});

  final CompanySearchPage? results;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final totalItems = results?.totalItems;
    final label = totalItems == null
        ? 'Entreprises actives'
        : totalItems <= 1
        ? '$totalItems entreprise active'
        : '$totalItems entreprises actives';

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (loading)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }
}

class _LoadingResults extends StatelessWidget {
  const _LoadingResults();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      key: ValueKey('loading-companies'),
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    return _StateBox(
      key: const ValueKey('empty-companies'),
      icon: Icons.search_off_outlined,
      title: 'Aucune entreprise trouvee',
      message: 'Essayez une recherche plus large ou retirez un filtre.',
    );
  }
}

class _ErrorResults extends StatelessWidget {
  const _ErrorResults({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _StateBox(
      key: const ValueKey('error-companies'),
      icon: Icons.wifi_off_outlined,
      title: 'Recherche indisponible',
      message: message,
      action: OutlinedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Reessayer'),
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
    super.key,
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

class _CompanyResultCard extends StatelessWidget {
  const _CompanyResultCard({required this.company});

  final CompanySummary company;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(FlowMovaRadii.medium),
        onTap: () => Navigator.pushNamed(context, AppRoutes.companyDetail),
        child: Padding(
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
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _BusinessTypeChip(type: company.businessType),
                ],
              ),
              if (company.description != null &&
                  company.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  company.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: FlowMovaColors.slate,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoPill(
                    icon: Icons.place_outlined,
                    label: company.locationLabel,
                  ),
                  _InfoPill(
                    icon: Icons.payments_outlined,
                    label: company.currency,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusinessTypeChip extends StatelessWidget {
  const _BusinessTypeChip({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FlowMovaColors.primaryAqua.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(FlowMovaRadii.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          _businessTypeLabel(type),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: FlowMovaColors.logoInk,
            fontWeight: FontWeight.w700,
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

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.results,
    required this.loading,
    required this.onPrevious,
    required this.onNext,
  });

  final CompanySearchPage results;
  final bool loading;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final pageLabel = results.totalPages == 0
        ? 'Page 0 / 0'
        : 'Page ${results.page + 1} / ${results.totalPages}';

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          IconButton.outlined(
            tooltip: 'Page precedente',
            onPressed: !loading && results.hasPreviousPage ? onPrevious : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              pageLabel,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton.outlined(
            tooltip: 'Page suivante',
            onPressed: !loading && results.hasNextPage ? onNext : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
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
