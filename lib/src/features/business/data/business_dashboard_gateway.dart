import '../../../core/api/api_client.dart';
import '../../client/data/company_detail_gateway.dart';

abstract interface class BusinessDashboardGateway {
  Future<BusinessDashboardBundle> getDashboard(String companyId);
}

class BackendBusinessDashboardGateway implements BusinessDashboardGateway {
  const BackendBusinessDashboardGateway(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<BusinessDashboardBundle> getDashboard(String companyId) async {
    final companyResponse = await _apiClient.get('/api/companies/$companyId');
    final serviceUnitsResponse = await _apiClient.get(
      '/api/companies/$companyId/admin/service-units',
      queryParameters: {'page': 0, 'size': 6, 'sort': 'name,asc'},
    );
    final catalogCategoriesResponse = await _apiClient.get(
      '/api/companies/$companyId/catalog-categories',
    );
    final catalogsResponse = await _apiClient.get(
      '/api/companies/$companyId/catalogs',
    );

    if (companyResponse is! Map<String, dynamic>) {
      throw const FormatException('Invalid business dashboard company.');
    }
    if (serviceUnitsResponse is! Map<String, dynamic>) {
      throw const FormatException('Invalid business dashboard services.');
    }
    if (catalogCategoriesResponse is! List) {
      throw const FormatException(
        'Invalid business dashboard catalog categories.',
      );
    }
    if (catalogsResponse is! List) {
      throw const FormatException('Invalid business dashboard catalogs.');
    }

    return BusinessDashboardBundle(
      company: CompanyDetail.fromJson(companyResponse),
      services: BusinessServiceUnitPage.fromJson(serviceUnitsResponse),
      catalogCategories: catalogCategoriesResponse
          .whereType<Map<String, dynamic>>()
          .map(CompanyCatalogCategory.fromJson)
          .toList(growable: false),
      catalogs: catalogsResponse
          .whereType<Map<String, dynamic>>()
          .map(CompanyCatalogItem.fromJson)
          .toList(growable: false),
    );
  }
}

class BusinessDashboardBundle {
  const BusinessDashboardBundle({
    required this.company,
    required this.services,
    required this.catalogCategories,
    required this.catalogs,
  });

  final CompanyDetail company;
  final BusinessServiceUnitPage services;
  final List<CompanyCatalogCategory> catalogCategories;
  final List<CompanyCatalogItem> catalogs;
}

class BusinessServiceUnitPage {
  const BusinessServiceUnitPage({
    required this.items,
    required this.page,
    required this.size,
    required this.totalItems,
    required this.totalPages,
  });

  factory BusinessServiceUnitPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is! List) {
      throw const FormatException('Invalid business service units items.');
    }

    return BusinessServiceUnitPage(
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(BusinessServiceUnit.fromJson)
          .toList(growable: false),
      page: json['page'] as int,
      size: json['size'] as int,
      totalItems: json['totalItems'] as int,
      totalPages: json['totalPages'] as int,
    );
  }

  final List<BusinessServiceUnit> items;
  final int page;
  final int size;
  final int totalItems;
  final int totalPages;
}

class BusinessServiceUnit {
  const BusinessServiceUnit({
    required this.id,
    required this.companyId,
    required this.name,
    required this.type,
    required this.status,
    required this.ticketCreationGuardMode,
    required this.creationEntryMode,
    this.description,
    this.location,
    this.defaultLocation,
  });

  factory BusinessServiceUnit.fromJson(Map<String, dynamic> json) {
    return BusinessServiceUnit(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      type: json['type'] as String,
      status: json['status'] as String,
      ticketCreationGuardMode: json['ticketCreationGuardMode'] as String,
      creationEntryMode:
          json['creationEntryMode'] as String? ?? 'PUBLIC_AND_QR',
      defaultLocation: json['defaultLocation'] is Map<String, dynamic>
          ? CompanyServiceUnitLocation.fromJson(
              json['defaultLocation'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  final String id;
  final String companyId;
  final String name;
  final String? description;
  final String? location;
  final String type;
  final String status;
  final String ticketCreationGuardMode;
  final String creationEntryMode;
  final CompanyServiceUnitLocation? defaultLocation;

  bool get isOpen => status == 'OPEN';

  bool get isQrOnly => creationEntryMode == 'QR_ONLY';
}
