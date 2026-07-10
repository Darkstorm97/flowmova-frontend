import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/session/auth_session_controller.dart';
import '../../../core/session/session_scope.dart';
import '../../../core/theme/flow_mova_colors.dart';
import '../data/current_user_companies_gateway.dart';

class MyCompaniesScreen extends StatefulWidget {
  const MyCompaniesScreen({super.key, this.gateway});

  final CurrentUserCompaniesGateway? gateway;

  @override
  State<MyCompaniesScreen> createState() => _MyCompaniesScreenState();
}

class _MyCompaniesScreenState extends State<MyCompaniesScreen> {
  static const _pageSize = 10;

  final TextEditingController _searchController = TextEditingController();

  CurrentUserCompaniesGateway? _gateway;
  Future<CurrentUserCompanyPage>? _companiesFuture;
  AuthSessionController? _sessionController;
  String _query = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final sessionController = SessionScope.of(context);
    if (_sessionController != sessionController) {
      _sessionController?.removeListener(_handleSessionChanged);
      _sessionController = sessionController;
      _sessionController!.addListener(_handleSessionChanged);
    }

    _gateway ??=
        widget.gateway ??
        BackendCurrentUserCompaniesGateway(
          ApiClient(accessTokenProvider: sessionController.currentAccessToken),
        );

    if (sessionController.isAuthenticated && _companiesFuture == null) {
      _companiesFuture = _gateway!.listCompanies(size: _pageSize);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final session = SessionScope.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mes entreprises',
            style: textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Retrouvez les entreprises rattachees a votre compte.',
            style: textTheme.titleMedium?.copyWith(color: FlowMovaColors.slate),
          ),
          const SizedBox(height: 24),
          if (session.status == AuthSessionStatus.unknown)
            const _CompaniesLoadingCard()
          else if (!session.isAuthenticated)
            _SignedOutCompaniesCard(
              isExpired: session.status == AuthSessionStatus.expired,
            )
          else
            FutureBuilder<CurrentUserCompanyPage>(
              future: _companiesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const _CompaniesLoadingCard();
                }

                if (snapshot.hasError) {
                  return _CompaniesErrorCard(
                    message: _errorMessage(snapshot.error),
                    onRetry: () => _loadPage(),
                  );
                }

                final page = snapshot.requireData;
                return _CompaniesLoadedState(
                  page: page,
                  query: _query,
                  searchController: _searchController,
                  onSearchChanged: (value) => setState(() => _query = value),
                  onClearSearch: _clearSearch,
                  onRefresh: () => _loadPage(page: page.page),
                  onPrevious: page.hasPreviousPage
                      ? () => _loadPage(page: page.page - 1)
                      : null,
                  onNext: page.hasNextPage
                      ? () => _loadPage(page: page.page + 1)
                      : null,
                  onOpenCompany: _openCompanyDashboard,
                );
              },
            ),
        ],
      ),
    );
  }

  void _handleSessionChanged() {
    final session = _sessionController;
    if (session == null || !mounted) {
      return;
    }

    setState(() {
      _companiesFuture = session.isAuthenticated
          ? _gateway!.listCompanies(size: _pageSize)
          : null;
    });
  }

  void _loadPage({int page = 0}) {
    setState(() {
      _companiesFuture = _gateway!.listCompanies(page: page, size: _pageSize);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  void _openCompanyDashboard(CurrentUserCompany company) {
    Navigator.pushNamed(
      context,
      AppRoutes.businessDashboard,
      arguments: company.id,
    );
  }

  String _errorMessage(Object? error) {
    if (error is ApiException) {
      return error.message;
    }
    if (error is FormatException) {
      return 'La liste des entreprises est illisible.';
    }
    return 'Impossible de charger vos entreprises pour le moment.';
  }

  @override
  void dispose() {
    _sessionController?.removeListener(_handleSessionChanged);
    _searchController.dispose();
    super.dispose();
  }
}

class _CompaniesLoadedState extends StatelessWidget {
  const _CompaniesLoadedState({
    required this.page,
    required this.query,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onRefresh,
    required this.onPrevious,
    required this.onNext,
    required this.onOpenCompany,
  });

  final CurrentUserCompanyPage page;
  final String query;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onRefresh;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<CurrentUserCompany> onOpenCompany;

  @override
  Widget build(BuildContext context) {
    final filteredCompanies = page.items
        .where((company) => _matchesCompany(company, query))
        .toList(growable: false);
    final hasQuery = query.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _companyCountLabel(
                  filteredCompanies.length,
                  page.totalItems,
                  hasQuery,
                ),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              tooltip: 'Rafraichir',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: searchController,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Rechercher par nom, ville, role...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: hasQuery
                ? IconButton(
                    tooltip: 'Effacer la recherche',
                    onPressed: onClearSearch,
                    icon: const Icon(Icons.close),
                  )
                : null,
          ),
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 14),
        if (page.items.isEmpty)
          const _EmptyCompaniesCard()
        else if (filteredCompanies.isEmpty)
          _EmptyCompanySearchCard(query: query)
        else
          for (final company in filteredCompanies) ...[
            _CompanyAdminCard(
              company: company,
              onTap: () => onOpenCompany(company),
            ),
            const SizedBox(height: 12),
          ],
        if (page.totalPages > 1) ...[
          const SizedBox(height: 4),
          _CompaniesPagination(
            page: page,
            onPrevious: onPrevious,
            onNext: onNext,
          ),
        ],
      ],
    );
  }

  bool _matchesCompany(CurrentUserCompany company, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return true;
    }

    final values = [
      company.name,
      company.description,
      company.businessType,
      company.city,
      company.region,
      company.country,
      company.status,
      company.operationalStatus,
      company.role,
      _roleLabel(company.role),
      _businessTypeLabel(company.businessType),
      _statusLabel(company.status),
      _operationalStatusLabel(company.operationalStatus),
    ];

    return values.whereType<String>().any(
      (value) => value.toLowerCase().contains(normalizedQuery),
    );
  }

  String _companyCountLabel(int filteredCount, int totalItems, bool hasQuery) {
    final totalLabel = '$totalItems entreprise${totalItems > 1 ? 's' : ''}';
    if (!hasQuery || filteredCount == totalItems) {
      return totalLabel;
    }

    return '$filteredCount resultat${filteredCount > 1 ? 's' : ''} sur $totalLabel';
  }
}

class _CompanyAdminCard extends StatelessWidget {
  const _CompanyAdminCard({required this.company, required this.onTap});

  final CurrentUserCompany company;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (company.imageUrl != null && company.imageUrl!.trim().isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 7,
                child: Image.network(
                  company.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _CompanyImageFallback(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
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
                      _StatusPill(
                        label: _operationalStatusLabel(
                          company.operationalStatus,
                        ),
                        color: company.isOperationallyOpen
                            ? FlowMovaColors.leafGreen
                            : FlowMovaColors.slate,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaPill(
                        icon: Icons.badge_outlined,
                        label: _roleLabel(company.role),
                      ),
                      _MetaPill(
                        icon: Icons.storefront_outlined,
                        label: _businessTypeLabel(company.businessType),
                      ),
                      _MetaPill(
                        icon: Icons.verified_outlined,
                        label: _statusLabel(company.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (company.description != null &&
                      company.description!.trim().isNotEmpty) ...[
                    Text(
                      company.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: FlowMovaColors.slate,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: FlowMovaColors.slate,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          company.locationLabel,
                          style: textTheme.bodyMedium?.copyWith(
                            color: FlowMovaColors.slate,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right),
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

class _CompanyImageFallback extends StatelessWidget {
  const _CompanyImageFallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: FlowMovaColors.primaryAqua.withValues(alpha: 0.1),
      child: const Center(child: Icon(Icons.storefront_outlined, size: 42)),
    );
  }
}

class _SignedOutCompaniesCard extends StatelessWidget {
  const _SignedOutCompaniesCard({required this.isExpired});

  final bool isExpired;

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
              isExpired ? 'Session expiree' : 'Connectez-vous',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isExpired
                  ? 'Reconnectez-vous pour retrouver vos entreprises.'
                  : 'Vos entreprises apparaissent ici une fois connecte.',
              style: textTheme.bodyMedium?.copyWith(
                color: FlowMovaColors.slate,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.login),
                  child: const Text('Se connecter'),
                ),
                OutlinedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.register),
                  child: const Text('Creer un compte'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCompaniesCard extends StatelessWidget {
  const _EmptyCompaniesCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.storefront_outlined),
            const SizedBox(height: 12),
            Text(
              'Aucune entreprise',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Les entreprises rattachees a votre compte apparaitront ici.',
              style: textTheme.bodyMedium?.copyWith(
                color: FlowMovaColors.slate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCompanySearchCard extends StatelessWidget {
  const _EmptyCompanySearchCard({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.search_off_outlined),
            const SizedBox(height: 12),
            Text(
              'Aucune entreprise trouvee',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Aucune entreprise ne correspond a "$query".',
              style: textTheme.bodyMedium?.copyWith(
                color: FlowMovaColors.slate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompaniesLoadingCard extends StatelessWidget {
  const _CompaniesLoadingCard();

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
            Text('Chargement des entreprises...'),
          ],
        ),
      ),
    );
  }
}

class _CompaniesErrorCard extends StatelessWidget {
  const _CompaniesErrorCard({required this.message, required this.onRetry});

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
              'Entreprises indisponibles',
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

class _CompaniesPagination extends StatelessWidget {
  const _CompaniesPagination({
    required this.page,
    required this.onPrevious,
    required this.onNext,
  });

  final CurrentUserCompanyPage page;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Page precedente',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            'Page ${page.page + 1} sur ${page.totalPages}',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        IconButton(
          tooltip: 'Page suivante',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
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

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

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

String _roleLabel(String role) {
  return switch (role) {
    'ADMIN' => 'Admin',
    'EMPLOYEE' => 'Employe',
    _ => role,
  };
}

String _businessTypeLabel(String businessType) {
  return switch (businessType) {
    'RESTAURANT' => 'Restauration',
    'RETAIL' => 'Commerce',
    'SERVICE' => 'Service',
    'HEALTHCARE' => 'Sante',
    'EDUCATION' => 'Education',
    'OTHER' => 'Autre',
    _ => businessType,
  };
}

String _statusLabel(String status) {
  return switch (status) {
    'ACTIVE' => 'Active',
    'INACTIVE' => 'Inactive',
    _ => status,
  };
}

String _operationalStatusLabel(String status) {
  return switch (status) {
    'OPEN' => 'Ouverte',
    'CLOSED' => 'Fermee',
    _ => status,
  };
}
