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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DiscoveryHeader(
          searchController: _searchController,
          loading: _loading,
          onSubmit: () => _search(page: 0),
          onQrPressed: () =>
              Navigator.pushNamed(context, AppRoutes.publicLocationScan),
        ),
        const SizedBox(height: 16),
        _DomainScroller(
          selectedBusinessType: _selectedBusinessType,
          onSelected: (value) {
            setState(() => _selectedBusinessType = value);
            _search(page: 0);
          },
        ),
        const SizedBox(height: 12),
        _AdvancedFilters(
          cityController: _cityController,
          countryController: _countryController,
          loading: _loading,
          onSubmit: () => _search(page: 0),
          onReset: _resetFilters,
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _buildResults(),
        ),
      ],
    );
  }

  Widget _buildResults() {
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
      key: ValueKey('companies-feed-${results.page}'),
      children: [
        for (final company in results.items) ...[
          _CompanyFeedCard(company: company),
          const SizedBox(height: 12),
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
    _countryController.clear();
    setState(() => _selectedBusinessType = null);
    _search(page: 0);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }
}

class _DiscoveryHeader extends StatelessWidget {
  const _DiscoveryHeader({
    required this.searchController,
    required this.loading,
    required this.onSubmit,
    required this.onQrPressed,
  });

  final TextEditingController searchController;
  final bool loading;
  final VoidCallback onSubmit;
  final VoidCallback onQrPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: FlowMovaColors.white,
        border: Border.all(color: FlowMovaColors.border),
        borderRadius: BorderRadius.circular(FlowMovaRadii.large),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Decouvrez autour de vous',
                        style: textTheme.titleLarge?.copyWith(
                          color: FlowMovaColors.logoInk,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Trouvez vite le bon service.',
                        style: textTheme.bodySmall?.copyWith(
                          color: FlowMovaColors.slate,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  tooltip: 'Scanner un QR code',
                  onPressed: onQrPressed,
                  icon: const Icon(Icons.qr_code_scanner_outlined),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_outlined),
                hintText: 'Restaurant, salon, service...',
                suffixIcon: loading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        tooltip: 'Rechercher',
                        onPressed: onSubmit,
                        icon: const Icon(Icons.arrow_forward),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DomainScroller extends StatelessWidget {
  const _DomainScroller({
    required this.selectedBusinessType,
    required this.onSelected,
  });

  final String? selectedBusinessType;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _businessTypeOptions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = _businessTypeOptions[index];
          return ChoiceChip(
            selected: option.value == selectedBusinessType,
            showCheckmark: false,
            avatar: Icon(option.icon, size: 18),
            label: Text(option.label),
            onSelected: (_) => onSelected(option.value),
          );
        },
      ),
    );
  }
}

class _AdvancedFilters extends StatelessWidget {
  const _AdvancedFilters({
    required this.cityController,
    required this.countryController,
    required this.loading,
    required this.onSubmit,
    required this.onReset,
  });

  final TextEditingController cityController;
  final TextEditingController countryController;
  final bool loading;
  final VoidCallback onSubmit;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      shape: const Border(),
      collapsedShape: const Border(),
      leading: const Icon(Icons.tune_outlined),
      title: Text(
        'Affiner par localisation',
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 620;
                    final fields = [
                      _FilterTextField(
                        controller: cityController,
                        label: 'Ville',
                        icon: Icons.location_city_outlined,
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

                    return Row(
                      children: [
                        for (final field in fields) ...[
                          Expanded(child: field),
                          if (field != fields.last) const SizedBox(width: 10),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: loading ? null : onSubmit,
                        icon: const Icon(Icons.search),
                        label: const Text('Appliquer'),
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
        ),
      ],
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

class _CompanyFeedCard extends StatelessWidget {
  const _CompanyFeedCard({required this.company});

  final CompanySummary company;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.companyDetail,
          arguments: company.id,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 520;

            if (compact) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CompanyAvatar(
                      type: company.businessType,
                      imageUrl: company.imageUrl,
                      width: double.infinity,
                      height: 142,
                    ),
                    const SizedBox(height: 12),
                    _CompanyFeedCardContent(company: company),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CompanyAvatar(
                    type: company.businessType,
                    imageUrl: company.imageUrl,
                    width: 124,
                    height: 96,
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: _CompanyFeedCardContent(company: company)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CompanyFeedCardContent extends StatelessWidget {
  const _CompanyFeedCardContent({required this.company});

  final CompanySummary company;

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
              child: Text(
                company.name,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _OperationalBadge(status: company.operationalStatus),
          ],
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoPill(
              icon: _businessTypeIcon(company.businessType),
              label: _businessTypeLabel(company.businessType),
            ),
            _InfoPill(icon: Icons.place_outlined, label: company.locationLabel),
          ],
        ),
        if (company.description != null &&
            company.description!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            company.description!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(color: FlowMovaColors.slate),
          ),
        ],
      ],
    );
  }
}

class _CompanyAvatar extends StatelessWidget {
  const _CompanyAvatar({
    required this.type,
    required this.imageUrl,
    required this.width,
    required this.height,
  });

  final String type;
  final String? imageUrl;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: _businessTypeColor(type).withValues(alpha: 0.16),
      child: Center(
        child: Icon(
          _businessTypeIcon(type),
          size: 32,
          color: _businessTypeColor(type),
        ),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(FlowMovaRadii.medium),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(FlowMovaRadii.medium),
        child: SizedBox(
          width: width,
          height: height,
          child: imageUrl == null || imageUrl!.trim().isEmpty
              ? fallback
              : Image.network(
                  imageUrl!.trim(),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => fallback,
                ),
        ),
      ),
    );
  }
}

class _OperationalBadge extends StatelessWidget {
  const _OperationalBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isOpen = status == 'OPEN';
    final color = isOpen ? FlowMovaColors.leafGreen : FlowMovaColors.error;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(FlowMovaRadii.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOpen ? Icons.check_circle_outline : Icons.do_not_disturb_on,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              isOpen ? 'Ouvert' : 'Ferme',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
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

class _BusinessTypeOption {
  const _BusinessTypeOption(this.value, this.label, this.icon);

  final String? value;
  final String label;
  final IconData icon;
}

const _businessTypeOptions = [
  _BusinessTypeOption(null, 'Tous', Icons.auto_awesome_outlined),
  _BusinessTypeOption('RESTAURANT', 'Restauration', Icons.restaurant_outlined),
  _BusinessTypeOption('HAIR_SALON', 'Coiffure', Icons.content_cut_outlined),
  _BusinessTypeOption('RETAIL', 'Commerce', Icons.shopping_bag_outlined),
  _BusinessTypeOption('HEALTHCARE', 'Sante', Icons.local_hospital_outlined),
  _BusinessTypeOption(
    'ADMINISTRATION',
    'Administration',
    Icons.account_balance_outlined,
  ),
  _BusinessTypeOption('SERVICE', 'Service', Icons.handshake_outlined),
  _BusinessTypeOption('OTHER', 'Autre', Icons.more_horiz_outlined),
];

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
