import '../../../core/api/api_client.dart';
import 'company_search_gateway.dart';

abstract interface class CompanyDetailGateway {
  Future<CompanyDetailBundle> getDetail(String companyId);

  Future<CompanyServiceUnitDetail> getServiceUnitDetail(
    String companyId,
    String serviceUnitId,
  );
}

class BackendCompanyDetailGateway implements CompanyDetailGateway {
  const BackendCompanyDetailGateway(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<CompanyDetailBundle> getDetail(String companyId) async {
    final companyResponse = await _apiClient.get('/api/companies/$companyId');
    final catalogCategoriesResponse = await _apiClient.get(
      '/api/companies/$companyId/catalog-categories',
    );
    final catalogsResponse = await _apiClient.get(
      '/api/companies/$companyId/catalogs',
    );
    final serviceUnitsResponse = await _apiClient.get(
      '/api/companies/$companyId/service-units',
    );

    if (companyResponse is! Map<String, dynamic>) {
      throw const FormatException('Invalid company detail response payload.');
    }

    if (catalogsResponse is! List) {
      throw const FormatException('Invalid company catalogs response payload.');
    }

    if (catalogCategoriesResponse is! List) {
      throw const FormatException(
        'Invalid company catalog categories response payload.',
      );
    }

    if (serviceUnitsResponse is! List) {
      throw const FormatException(
        'Invalid company service units response payload.',
      );
    }

    return CompanyDetailBundle(
      company: CompanyDetail.fromJson(companyResponse),
      catalogCategories: catalogCategoriesResponse
          .whereType<Map<String, dynamic>>()
          .map(CompanyCatalogCategory.fromJson)
          .toList(growable: false),
      catalogs: catalogsResponse
          .whereType<Map<String, dynamic>>()
          .map(CompanyCatalogItem.fromJson)
          .toList(growable: false),
      serviceUnits: serviceUnitsResponse
          .whereType<Map<String, dynamic>>()
          .map(CompanyServiceUnitItem.fromJson)
          .toList(growable: false),
    );
  }

  @override
  Future<CompanyServiceUnitDetail> getServiceUnitDetail(
    String companyId,
    String serviceUnitId,
  ) async {
    final response = await _apiClient.get(
      '/api/companies/$companyId/service-units/$serviceUnitId',
    );

    if (response is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid company service unit detail response payload.',
      );
    }

    return CompanyServiceUnitDetail.fromJson(response);
  }
}

class CompanyDetailBundle {
  const CompanyDetailBundle({
    required this.company,
    required this.catalogCategories,
    required this.catalogs,
    required this.serviceUnits,
  });

  final CompanyDetail company;
  final List<CompanyCatalogCategory> catalogCategories;
  final List<CompanyCatalogItem> catalogs;
  final List<CompanyServiceUnitItem> serviceUnits;
}

class CompanyDetail {
  const CompanyDetail({
    required this.id,
    required this.name,
    required this.currency,
    required this.businessType,
    required this.status,
    this.operationalStatus = 'OPEN',
    this.description,
    this.imageUrl,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.region,
    this.postalCode,
    this.country,
  });

  factory CompanyDetail.fromJson(Map<String, dynamic> json) {
    return CompanyDetail(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      currency: json['currency'] as String,
      businessType: json['businessType'] as String,
      addressLine1: json['addressLine1'] as String?,
      addressLine2: json['addressLine2'] as String?,
      city: json['city'] as String?,
      region: json['region'] as String?,
      postalCode: json['postalCode'] as String?,
      country: json['country'] as String?,
      status: json['status'] as String,
      operationalStatus: json['operationalStatus'] as String? ?? 'OPEN',
    );
  }

  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String currency;
  final String businessType;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? region;
  final String? postalCode;
  final String? country;
  final String status;
  final String operationalStatus;

  bool get isOperationallyOpen => operationalStatus == 'OPEN';

  String get locationLabel {
    final parts = [city, region, country]
        .where((part) => part != null && part.trim().isNotEmpty)
        .cast<String>()
        .toList(growable: false);
    return parts.isEmpty ? 'Adresse a confirmer' : parts.join(', ');
  }

  String get addressLabel {
    final parts = [
      addressLine1,
      addressLine2,
      city,
      region,
      postalCode,
      country,
    ].where((part) => part != null && part.trim().isNotEmpty).cast<String>();
    return parts.isEmpty ? locationLabel : parts.join(', ');
  }

  CompanySummary toSummary() {
    return CompanySummary(
      id: id,
      name: name,
      description: description,
      imageUrl: imageUrl,
      currency: currency,
      businessType: businessType,
      city: city,
      region: region,
      country: country,
      status: status,
      operationalStatus: operationalStatus,
    );
  }
}

class CompanyCatalogCategory {
  const CompanyCatalogCategory({
    required this.id,
    required this.companyId,
    required this.name,
    required this.displayOrder,
    required this.status,
    this.description,
  });

  factory CompanyCatalogCategory.fromJson(Map<String, dynamic> json) {
    return CompanyCatalogCategory(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      displayOrder: json['displayOrder'] as int,
      status: json['status'] as String,
    );
  }

  final String id;
  final String companyId;
  final String name;
  final String? description;
  final int displayOrder;
  final String status;
}

class CompanyCatalogItem {
  const CompanyCatalogItem({
    required this.id,
    required this.name,
    required this.status,
    required this.catalogCategoryId,
    this.description,
    this.imageUrl,
    this.priceAmount,
  });

  factory CompanyCatalogItem.fromJson(Map<String, dynamic> json) {
    return CompanyCatalogItem(
      id: json['id'] as String,
      name: json['name'] as String,
      catalogCategoryId: json['catalogCategoryId'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      priceAmount: json['priceAmount'] as num?,
      status: json['status'] as String,
    );
  }

  final String id;
  final String name;
  final String catalogCategoryId;
  final String? description;
  final String? imageUrl;
  final num? priceAmount;
  final String status;

  String get priceLabel {
    final amount = priceAmount;
    if (amount == null) {
      return 'Prix a confirmer';
    }
    return '${amount.toStringAsFixed(2)} \$';
  }
}

class CompanyServiceUnitItem {
  const CompanyServiceUnitItem({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.ticketCreationGuardMode,
    this.creationEntryMode = 'PUBLIC_AND_QR',
    this.allowTicketWithoutItems = true,
    this.description,
    this.location,
  });

  factory CompanyServiceUnitItem.fromJson(Map<String, dynamic> json) {
    return CompanyServiceUnitItem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      type: json['type'] as String,
      status: json['status'] as String,
      ticketCreationGuardMode: json['ticketCreationGuardMode'] as String,
      creationEntryMode:
          json['creationEntryMode'] as String? ?? 'PUBLIC_AND_QR',
      allowTicketWithoutItems: json['allowTicketWithoutItems'] as bool? ?? true,
    );
  }

  final String id;
  final String name;
  final String? description;
  final String? location;
  final String type;
  final String status;
  final String ticketCreationGuardMode;
  final String creationEntryMode;
  final bool allowTicketWithoutItems;

  bool get requiresQrCode => creationEntryMode == 'QR_ONLY';

  bool get canCreateFromCompanyDetail => !requiresQrCode;
}

class CompanyServiceUnitDetail {
  const CompanyServiceUnitDetail({
    required this.id,
    required this.companyId,
    required this.name,
    required this.type,
    required this.status,
    required this.ticketCreationGuardMode,
    required this.locations,
    required this.items,
    this.creationEntryMode = 'PUBLIC_AND_QR',
    this.allowTicketWithoutItems = true,
    this.description,
    this.location,
    this.defaultLocation,
  });

  factory CompanyServiceUnitDetail.fromJson(Map<String, dynamic> json) {
    final rawLocations = json['locations'];
    final rawItems = json['items'];

    return CompanyServiceUnitDetail(
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
      allowTicketWithoutItems: json['allowTicketWithoutItems'] as bool? ?? true,
      defaultLocation: json['defaultLocation'] is Map<String, dynamic>
          ? CompanyServiceUnitLocation.fromJson(
              json['defaultLocation'] as Map<String, dynamic>,
            )
          : null,
      locations: rawLocations is List
          ? rawLocations
                .whereType<Map<String, dynamic>>()
                .map(CompanyServiceUnitLocation.fromJson)
                .toList(growable: false)
          : const [],
      items: rawItems is List
          ? rawItems
                .whereType<Map<String, dynamic>>()
                .map(CompanyServiceUnitAvailableItem.fromJson)
                .toList(growable: false)
          : const [],
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
  final bool allowTicketWithoutItems;
  final CompanyServiceUnitLocation? defaultLocation;
  final List<CompanyServiceUnitLocation> locations;
  final List<CompanyServiceUnitAvailableItem> items;

  bool get requiresQrCode => creationEntryMode == 'QR_ONLY';
}

class CompanyServiceUnitLocation {
  const CompanyServiceUnitLocation({
    required this.id,
    required this.serviceUnitId,
    required this.name,
    required this.type,
    required this.defaultLocation,
    required this.status,
    this.description,
    this.publicAccessSlug,
  });

  factory CompanyServiceUnitLocation.fromJson(Map<String, dynamic> json) {
    return CompanyServiceUnitLocation(
      id: json['id'] as String,
      serviceUnitId: json['serviceUnitId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: json['type'] as String,
      defaultLocation: json['defaultLocation'] as bool,
      status: json['status'] as String,
      publicAccessSlug: json['publicAccessSlug'] as String?,
    );
  }

  final String id;
  final String serviceUnitId;
  final String name;
  final String? description;
  final String type;
  final bool defaultLocation;
  final String status;
  final String? publicAccessSlug;
}

class CompanyServiceUnitAvailableItem {
  const CompanyServiceUnitAvailableItem({
    required this.id,
    required this.catalog,
    required this.priceAmount,
    required this.availability,
    required this.status,
  });

  factory CompanyServiceUnitAvailableItem.fromJson(Map<String, dynamic> json) {
    final catalog = json['catalog'];
    if (catalog is! Map<String, dynamic>) {
      throw const FormatException('Invalid service unit item catalog payload.');
    }

    return CompanyServiceUnitAvailableItem(
      id: json['id'] as String,
      catalog: CompanyCatalogItem.fromJson(catalog),
      priceAmount: json['priceAmount'] as num,
      availability: json['availability'] as String,
      status: json['status'] as String,
    );
  }

  final String id;
  final CompanyCatalogItem catalog;
  final num priceAmount;
  final String availability;
  final String status;

  String get priceLabel => '${priceAmount.toStringAsFixed(2)} \$';
}
