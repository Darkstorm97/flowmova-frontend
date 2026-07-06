import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/theme/flow_mova_colors.dart';
import '../../../core/theme/flow_mova_radii.dart';
import '../../../shared/widgets/flow_mova_app_bar_title.dart';
import '../data/company_detail_gateway.dart';

class CompanyDetailScreen extends StatefulWidget {
  const CompanyDetailScreen({
    required this.companyId,
    super.key,
    this.detailGateway,
  });

  final String companyId;
  final CompanyDetailGateway? detailGateway;

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
              return SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: _CompanyDetailContent(bundle: bundle),
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
}

class _CompanyDetailContent extends StatelessWidget {
  const _CompanyDetailContent({required this.bundle});

  final CompanyDetailBundle bundle;

  @override
  Widget build(BuildContext context) {
    final company = bundle.company;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CompanyHero(company: company),
        const SizedBox(height: 16),
        _QuickActions(company: company, serviceUnits: bundle.serviceUnits),
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
  const _QuickActions({required this.company, required this.serviceUnits});

  final CompanyDetail company;
  final List<CompanyServiceUnitItem> serviceUnits;

  @override
  Widget build(BuildContext context) {
    final firstServiceUnit = serviceUnits.isEmpty ? null : serviceUnits.first;

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: firstServiceUnit == null
                ? null
                : () => Navigator.pushNamed(
                    context,
                    AppRoutes.serviceUnitDetail,
                    arguments: {
                      'companyId': company.id,
                      'serviceUnitId': firstServiceUnit.id,
                    },
                  ),
            icon: const Icon(Icons.storefront_outlined),
            label: const Text('Voir les services'),
          ),
        ),
        const SizedBox(width: 10),
        IconButton.outlined(
          tooltip: 'Creer une demande',
          onPressed: firstServiceUnit == null
              ? null
              : () => Navigator.pushNamed(
                  context,
                  AppRoutes.createTicket,
                  arguments: {
                    'companyId': company.id,
                    'serviceUnitId': firstServiceUnit.id,
                  },
                ),
          icon: const Icon(Icons.add_task_outlined),
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
