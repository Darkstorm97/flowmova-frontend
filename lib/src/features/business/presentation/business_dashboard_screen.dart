import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/session/session_scope.dart';
import '../../../core/theme/flow_mova_colors.dart';
import '../../client/data/company_detail_gateway.dart';
import '../data/business_dashboard_gateway.dart';
import '../data/current_user_companies_gateway.dart';
import 'business_service_units_screen.dart';
import 'edit_company_screen.dart';

class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({
    super.key,
    required this.companyId,
    this.gateway,
  });

  final String companyId;
  final BusinessDashboardGateway? gateway;

  @override
  State<BusinessDashboardScreen> createState() =>
      _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> {
  BusinessDashboardGateway? _gateway;
  Future<BusinessDashboardBundle>? _dashboardFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final session = SessionScope.of(context);
    _gateway ??=
        widget.gateway ??
        BackendBusinessDashboardGateway(
          ApiClient(accessTokenProvider: session.currentAccessToken),
        );
    _dashboardFuture ??= _gateway!.getDashboard(widget.companyId);
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    if (!session.isAuthenticated) {
      return const _DashboardSignedOutCard();
    }

    return FutureBuilder<BusinessDashboardBundle>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _DashboardLoadingCard();
        }
        if (snapshot.hasError) {
          return _DashboardErrorCard(
            message: _errorMessage(snapshot.error),
            onRetry: _reload,
          );
        }

        return _DashboardContent(
          bundle: snapshot.requireData,
          onRefresh: _reload,
          onEditCompany: _openCompanyEdit,
        );
      },
    );
  }

  void _reload() {
    setState(() {
      _dashboardFuture = _gateway!.getDashboard(widget.companyId);
    });
  }

  Future<void> _openCompanyEdit(CompanyDetail company) async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.editCompany,
      arguments: EditCompanyArguments(company: _toCurrentUserCompany(company)),
    );
    if (result is CurrentUserCompany && mounted) {
      _reload();
    }
  }

  CurrentUserCompany _toCurrentUserCompany(CompanyDetail company) {
    final timestamp = DateTime.now().toUtc();
    return CurrentUserCompany(
      id: company.id,
      name: company.name,
      description: company.description,
      imageUrl: company.imageUrl,
      currency: company.currency,
      businessType: company.businessType,
      addressLine1: company.addressLine1,
      addressLine2: company.addressLine2,
      city: company.city,
      region: company.region,
      postalCode: company.postalCode,
      country: company.country,
      status: company.status,
      operationalStatus: company.operationalStatus,
      role: 'ADMIN',
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  String _errorMessage(Object? error) {
    if (error is ApiException) {
      return error.message;
    }
    if (error is FormatException) {
      return 'Les donnees du dashboard sont illisibles.';
    }
    return 'Impossible de charger le dashboard entreprise pour le moment.';
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.bundle,
    required this.onRefresh,
    required this.onEditCompany,
  });

  final BusinessDashboardBundle bundle;
  final VoidCallback onRefresh;
  final ValueChanged<CompanyDetail> onEditCompany;

  @override
  Widget build(BuildContext context) {
    final company = bundle.company;
    final openServices = bundle.services.items
        .where((service) => service.isOpen)
        .length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CompanyHeader(
            company: company,
            onRefresh: onRefresh,
            onEdit: () => onEditCompany(company),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricTile(
                icon: Icons.room_service_outlined,
                label: 'Services',
                value: '${bundle.services.totalItems}',
                helper: '$openServices ouverts',
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.businessServiceUnits,
                  arguments: BusinessServiceUnitsArguments(
                    companyId: company.id,
                  ),
                ),
              ),
              _MetricTile(
                icon: Icons.inventory_2_outlined,
                label: 'Articles',
                value: '${bundle.catalogs.length}',
                helper:
                    '${bundle.catalogCategories.length} categorie${bundle.catalogCategories.length > 1 ? 's' : ''}',
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.businessServiceUnits,
                  arguments: BusinessServiceUnitsArguments(
                    companyId: company.id,
                  ),
                ),
              ),
              _MetricTile(
                icon: Icons.confirmation_number_outlined,
                label: 'Tickets',
                value: 'Suivi',
                helper: 'par service',
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.businessServiceUnits,
                  arguments: BusinessServiceUnitsArguments(
                    companyId: company.id,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ServicesPreview(services: bundle.services),
          const SizedBox(height: 14),
          _CatalogPreview(
            categories: bundle.catalogCategories,
            catalogs: bundle.catalogs,
          ),
        ],
      ),
    );
  }
}

class _CompanyHeader extends StatelessWidget {
  const _CompanyHeader({
    required this.company,
    required this.onRefresh,
    required this.onEdit,
  });

  final CompanyDetail company;
  final VoidCallback onRefresh;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final imageUrl = _absoluteImageUrl(company.imageUrl);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 7,
            child: imageUrl == null
                ? const _HeaderImageFallback()
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _HeaderImageFallback(),
                  ),
          ),
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
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Rafraichir',
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoPill(
                      icon: Icons.storefront_outlined,
                      label: _businessTypeLabel(company.businessType),
                    ),
                    _InfoPill(
                      icon: Icons.payments_outlined,
                      label: company.currency,
                    ),
                    _StatusPill(
                      label: company.isOperationallyOpen ? 'Ouverte' : 'Fermee',
                      color: company.isOperationallyOpen
                          ? FlowMovaColors.leafGreen
                          : FlowMovaColors.slate,
                    ),
                  ],
                ),
                if (company.description != null &&
                    company.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    company.description!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: FlowMovaColors.slate,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: FlowMovaColors.slate,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        company.addressLabel,
                        style: textTheme.bodyMedium?.copyWith(
                          color: FlowMovaColors.slate,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: Tooltip(
                    message: 'Modifier entreprise',
                    child: FilledButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Modifier'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
}

class _HeaderImageFallback extends StatelessWidget {
  const _HeaderImageFallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: FlowMovaColors.primaryAqua.withValues(alpha: 0.1),
      child: const Center(child: Icon(Icons.storefront_outlined, size: 44)),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.helper,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String helper;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: 150,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: FlowMovaColors.primaryAqua),
                const SizedBox(height: 10),
                Text(
                  value,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  helper,
                  style: textTheme.bodySmall?.copyWith(
                    color: FlowMovaColors.slate,
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

class _ServicesPreview extends StatelessWidget {
  const _ServicesPreview({required this.services});

  final BusinessServiceUnitPage services;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Services',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${services.totalItems}',
                  style: textTheme.titleMedium?.copyWith(
                    color: FlowMovaColors.slate,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (services.items.isEmpty)
              Text(
                'Aucun service configure pour le moment.',
                style: textTheme.bodyMedium?.copyWith(
                  color: FlowMovaColors.slate,
                ),
              )
            else
              for (final service in services.items) ...[
                _ServiceRow(service: service),
                if (service != services.items.last) const Divider(height: 18),
              ],
          ],
        ),
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.service});

  final BusinessServiceUnit service;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final location = service.defaultLocation?.name ?? service.location;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          service.isOpen
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
          size: 18,
          color: service.isOpen
              ? FlowMovaColors.leafGreen
              : FlowMovaColors.slate,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                service.name,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                [
                  _serviceTypeLabel(service.type),
                  if (location != null && location.trim().isNotEmpty) location,
                  if (service.isQrOnly) 'QR seulement',
                ].join(' - '),
                style: textTheme.bodySmall?.copyWith(
                  color: FlowMovaColors.slate,
                ),
              ),
            ],
          ),
        ),
        _StatusPill(
          label: service.isOpen
              ? 'Ouvert'
              : _serviceStatusLabel(service.status),
          color: service.isOpen
              ? FlowMovaColors.leafGreen
              : FlowMovaColors.slate,
        ),
      ],
    );
  }
}

class _CatalogPreview extends StatelessWidget {
  const _CatalogPreview({required this.categories, required this.catalogs});

  final List<CompanyCatalogCategory> categories;
  final List<CompanyCatalogItem> catalogs;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final visibleCatalogs = catalogs.take(4).toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Catalogue',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            if (catalogs.isEmpty)
              Text(
                'Aucun article de catalogue actif pour le moment.',
                style: textTheme.bodyMedium?.copyWith(
                  color: FlowMovaColors.slate,
                ),
              )
            else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoPill(
                    icon: Icons.category_outlined,
                    label:
                        '${categories.length} categorie${categories.length > 1 ? 's' : ''}',
                  ),
                  _InfoPill(
                    icon: Icons.inventory_2_outlined,
                    label:
                        '${catalogs.length} article${catalogs.length > 1 ? 's' : ''}',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final catalog in visibleCatalogs) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        catalog.name,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      catalog.priceLabel,
                      style: textTheme.bodySmall?.copyWith(
                        color: FlowMovaColors.slate,
                      ),
                    ),
                  ],
                ),
                if (catalog != visibleCatalogs.last) const SizedBox(height: 8),
              ],
            ],
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
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: FlowMovaColors.slate),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _DashboardLoadingCard extends StatelessWidget {
  const _DashboardLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Chargement du dashboard...'),
          ],
        ),
      ),
    );
  }
}

class _DashboardErrorCard extends StatelessWidget {
  const _DashboardErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard indisponible',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: FlowMovaColors.error,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardSignedOutCard extends StatelessWidget {
  const _DashboardSignedOutCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connectez-vous',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vous devez etre connecte pour administrer une entreprise.',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
              child: const Text('Se connecter'),
            ),
          ],
        ),
      ),
    );
  }
}

String _businessTypeLabel(String businessType) {
  return switch (businessType) {
    'RESTAURANT' => 'Restauration',
    'HAIR_SALON' => 'Salon de coiffure',
    'RETAIL' => 'Commerce',
    'HEALTHCARE' => 'Sante',
    'ADMINISTRATION' => 'Administration',
    'SERVICE' => 'Service',
    'OTHER' => 'Autre',
    _ => businessType,
  };
}

String _serviceTypeLabel(String type) {
  return switch (type) {
    'QUEUE' => 'File',
    'APPOINTMENT' => 'Rendez-vous',
    'ORDER' => 'Commande',
    'OTHER' => 'Autre',
    _ => type,
  };
}

String _serviceStatusLabel(String status) {
  return switch (status) {
    'OPEN' => 'Ouvert',
    'CLOSED' => 'Ferme',
    'ARCHIVED' => 'Archive',
    _ => status,
  };
}
