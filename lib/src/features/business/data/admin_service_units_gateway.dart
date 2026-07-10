import '../../../core/api/api_client.dart';
import '../../client/data/company_detail_gateway.dart';
import '../../tickets/data/current_user_ticket_gateway.dart';
import 'business_dashboard_gateway.dart';

abstract interface class AdminServiceUnitsGateway {
  Future<BusinessServiceUnitPage> listServiceUnits(
    String companyId, {
    int page = 0,
    int size = 20,
    String? status,
  });

  Future<BusinessServiceUnit> createServiceUnit(
    String companyId,
    ServiceUnitInput input,
  );

  Future<BusinessServiceUnit> updateServiceUnit(
    String companyId,
    String serviceUnitId,
    ServiceUnitInput input,
  );

  Future<BusinessServiceUnit> openServiceUnit(
    String companyId,
    String serviceUnitId,
  );

  Future<BusinessServiceUnit> closeServiceUnit(
    String companyId,
    String serviceUnitId,
  );

  Future<BusinessServiceUnit> archiveServiceUnit(
    String companyId,
    String serviceUnitId,
  );

  Future<BusinessServiceUnitLocationPage> listLocations(
    String companyId,
    String serviceUnitId, {
    int page = 0,
    int size = 20,
  });

  Future<BusinessServiceUnitLocation> createLocation(
    String companyId,
    String serviceUnitId,
    ServiceUnitLocationInput input,
  );

  Future<CurrentUserTicketPage> listTickets(
    String companyId,
    String serviceUnitId, {
    int page = 0,
    int size = 20,
    String? status,
    String? ticketNumber,
    String? locationId,
  });

  Future<CurrentUserTicket> changeTicketStatus(
    String companyId,
    String serviceUnitId,
    String ticketId,
    String status,
  );

  Future<List<BusinessServiceUnitItem>> listItems(
    String companyId,
    String serviceUnitId,
  );

  Future<BusinessServiceUnitItem> createItem(
    String companyId,
    String serviceUnitId,
    ServiceUnitItemInput input,
  );

  Future<BusinessServiceUnitItem> updateItem(
    String companyId,
    String serviceUnitId,
    String itemId,
    ServiceUnitItemInput input,
  );
}

class BackendAdminServiceUnitsGateway implements AdminServiceUnitsGateway {
  const BackendAdminServiceUnitsGateway(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<BusinessServiceUnitPage> listServiceUnits(
    String companyId, {
    int page = 0,
    int size = 20,
    String? status,
  }) async {
    final response = await _apiClient.get(
      '/api/companies/$companyId/admin/service-units',
      queryParameters: {
        'page': page,
        'size': size,
        'sort': 'name,asc',
        if (status != null && status.trim().isNotEmpty) 'status': status,
      },
    );

    if (response is! Map<String, dynamic>) {
      throw const FormatException('Invalid admin service units response.');
    }
    return BusinessServiceUnitPage.fromJson(response);
  }

  @override
  Future<BusinessServiceUnit> createServiceUnit(
    String companyId,
    ServiceUnitInput input,
  ) async {
    final response = await _apiClient.post(
      '/api/companies/$companyId/service-units',
      body: input.toJson(includeType: true),
    );
    return _serviceUnitFromResponse(response);
  }

  @override
  Future<BusinessServiceUnit> updateServiceUnit(
    String companyId,
    String serviceUnitId,
    ServiceUnitInput input,
  ) async {
    final response = await _apiClient.put(
      '/api/companies/$companyId/admin/service-units/$serviceUnitId',
      body: input.toJson(),
    );
    return _serviceUnitFromResponse(response);
  }

  @override
  Future<BusinessServiceUnit> openServiceUnit(
    String companyId,
    String serviceUnitId,
  ) async {
    final response = await _apiClient.post(
      '/api/companies/$companyId/service-units/$serviceUnitId/open',
    );
    return _serviceUnitFromResponse(response);
  }

  @override
  Future<BusinessServiceUnit> closeServiceUnit(
    String companyId,
    String serviceUnitId,
  ) async {
    final response = await _apiClient.post(
      '/api/companies/$companyId/admin/service-units/$serviceUnitId/close',
    );
    return _serviceUnitFromResponse(response);
  }

  @override
  Future<BusinessServiceUnit> archiveServiceUnit(
    String companyId,
    String serviceUnitId,
  ) async {
    final response = await _apiClient.post(
      '/api/companies/$companyId/admin/service-units/$serviceUnitId/archive',
    );
    return _serviceUnitFromResponse(response);
  }

  @override
  Future<BusinessServiceUnitLocationPage> listLocations(
    String companyId,
    String serviceUnitId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _apiClient.get(
      '/api/companies/$companyId/admin/service-units/$serviceUnitId/locations',
      queryParameters: {'page': page, 'size': size, 'sort': 'name,asc'},
    );
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Invalid admin service locations response.');
    }
    return BusinessServiceUnitLocationPage.fromJson(response);
  }

  @override
  Future<BusinessServiceUnitLocation> createLocation(
    String companyId,
    String serviceUnitId,
    ServiceUnitLocationInput input,
  ) async {
    final response = await _apiClient.post(
      '/api/companies/$companyId/admin/service-units/$serviceUnitId/locations',
      body: input.toJson(),
    );
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Invalid service location response.');
    }
    return BusinessServiceUnitLocation.fromJson(response);
  }

  @override
  Future<CurrentUserTicketPage> listTickets(
    String companyId,
    String serviceUnitId, {
    int page = 0,
    int size = 20,
    String? status,
    String? ticketNumber,
    String? locationId,
  }) async {
    final response = await _apiClient.get(
      '/api/companies/$companyId/admin/service-units/$serviceUnitId/tickets',
      queryParameters: {
        'page': page,
        'size': size,
        'sort': 'createdAt,desc',
        if (status != null && status.trim().isNotEmpty) 'status': status,
        if (ticketNumber != null && ticketNumber.trim().isNotEmpty)
          'ticketNumber': ticketNumber.trim(),
        if (locationId != null && locationId.trim().isNotEmpty)
          'locationId': locationId,
      },
    );
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Invalid admin tickets response.');
    }
    return CurrentUserTicketPage.fromJson(response);
  }

  @override
  Future<CurrentUserTicket> changeTicketStatus(
    String companyId,
    String serviceUnitId,
    String ticketId,
    String status,
  ) async {
    final response = await _apiClient.patch(
      '/api/companies/$companyId/admin/service-units/$serviceUnitId/tickets/$ticketId/status',
      body: {'status': status},
    );
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Invalid admin ticket response.');
    }
    return CurrentUserTicket.fromJson(response);
  }

  @override
  Future<List<BusinessServiceUnitItem>> listItems(
    String companyId,
    String serviceUnitId,
  ) async {
    final response = await _apiClient.get(
      '/api/companies/$companyId/admin/service-units/$serviceUnitId/items',
    );
    if (response is! List) {
      throw const FormatException('Invalid service items response.');
    }
    return response
        .whereType<Map<String, dynamic>>()
        .map(BusinessServiceUnitItem.fromJson)
        .toList(growable: false);
  }

  @override
  Future<BusinessServiceUnitItem> createItem(
    String companyId,
    String serviceUnitId,
    ServiceUnitItemInput input,
  ) async {
    final response = await _apiClient.post(
      '/api/companies/$companyId/admin/service-units/$serviceUnitId/items',
      body: input.toCreateJson(),
    );
    return _itemFromResponse(response);
  }

  @override
  Future<BusinessServiceUnitItem> updateItem(
    String companyId,
    String serviceUnitId,
    String itemId,
    ServiceUnitItemInput input,
  ) async {
    final response = await _apiClient.put(
      '/api/companies/$companyId/admin/service-units/$serviceUnitId/items/$itemId',
      body: input.toUpdateJson(),
    );
    return _itemFromResponse(response);
  }

  BusinessServiceUnit _serviceUnitFromResponse(Object? response) {
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Invalid service unit response.');
    }
    return BusinessServiceUnit.fromJson(response);
  }

  BusinessServiceUnitItem _itemFromResponse(Object? response) {
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Invalid service item response.');
    }
    return BusinessServiceUnitItem.fromJson(response);
  }
}

class ServiceUnitInput {
  const ServiceUnitInput({
    required this.name,
    required this.ticketCreationGuardMode,
    required this.creationEntryMode,
    this.allowTicketWithoutItems = true,
    this.description,
    this.location,
  });

  final String name;
  final String? description;
  final String? location;
  final String ticketCreationGuardMode;
  final String creationEntryMode;
  final bool allowTicketWithoutItems;

  Map<String, Object?> toJson({bool includeType = false}) {
    return {
      'name': name.trim(),
      'description': _blankToNull(description),
      'location': _blankToNull(location),
      if (includeType) 'type': 'TICKET_QUEUE',
      'ticketCreationGuardMode': ticketCreationGuardMode,
      'creationEntryMode': creationEntryMode,
      'allowTicketWithoutItems': allowTicketWithoutItems,
    };
  }
}

class ServiceUnitLocationInput {
  const ServiceUnitLocationInput({required this.name, this.description});

  final String name;
  final String? description;

  Map<String, Object?> toJson() {
    return {'name': name.trim(), 'description': _blankToNull(description)};
  }
}

class ServiceUnitItemInput {
  const ServiceUnitItemInput({
    required this.catalogId,
    required this.availability,
    required this.displayOrder,
    this.priceAmount,
    this.configuredQuantity,
  });

  final String catalogId;
  final num? priceAmount;
  final String availability;
  final int? configuredQuantity;
  final int displayOrder;

  Map<String, Object?> toCreateJson() {
    return {
      'catalogId': catalogId,
      'priceAmount': priceAmount,
      'availability': availability,
      'configuredQuantity': configuredQuantity,
      'displayOrder': displayOrder,
    };
  }

  Map<String, Object?> toUpdateJson() {
    return {
      'priceAmount': priceAmount,
      'availability': availability,
      'configuredQuantity': configuredQuantity,
      'displayOrder': displayOrder,
    };
  }
}

class BusinessServiceUnitLocationPage {
  const BusinessServiceUnitLocationPage({
    required this.items,
    required this.page,
    required this.size,
    required this.totalItems,
    required this.totalPages,
  });

  factory BusinessServiceUnitLocationPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is! List) {
      throw const FormatException('Invalid service location items.');
    }

    return BusinessServiceUnitLocationPage(
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(BusinessServiceUnitLocation.fromJson)
          .toList(growable: false),
      page: json['page'] as int,
      size: json['size'] as int,
      totalItems: json['totalItems'] as int,
      totalPages: json['totalPages'] as int,
    );
  }

  final List<BusinessServiceUnitLocation> items;
  final int page;
  final int size;
  final int totalItems;
  final int totalPages;
}

class BusinessServiceUnitLocation {
  const BusinessServiceUnitLocation({
    required this.id,
    required this.serviceUnitId,
    required this.name,
    required this.type,
    required this.defaultLocation,
    required this.status,
    this.description,
    this.publicAccessSlug,
    this.publicUrl,
  });

  factory BusinessServiceUnitLocation.fromJson(Map<String, dynamic> json) {
    return BusinessServiceUnitLocation(
      id: json['id'] as String,
      serviceUnitId: json['serviceUnitId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: json['type'] as String,
      defaultLocation: json['defaultLocation'] as bool,
      publicAccessSlug: json['publicAccessSlug'] as String?,
      publicUrl: json['publicUrl'] as String?,
      status: json['status'] as String,
    );
  }

  final String id;
  final String serviceUnitId;
  final String name;
  final String? description;
  final String type;
  final bool defaultLocation;
  final String? publicAccessSlug;
  final String? publicUrl;
  final String status;
}

class BusinessServiceUnitItem {
  const BusinessServiceUnitItem({
    required this.id,
    required this.serviceUnitId,
    required this.catalog,
    required this.availability,
    required this.reservedQuantity,
    required this.displayOrder,
    required this.status,
    this.priceAmount,
    this.configuredQuantity,
  });

  factory BusinessServiceUnitItem.fromJson(Map<String, dynamic> json) {
    final catalog = json['catalog'];
    if (catalog is! Map<String, dynamic>) {
      throw const FormatException('Invalid service item catalog.');
    }

    return BusinessServiceUnitItem(
      id: json['id'] as String,
      serviceUnitId: json['serviceUnitId'] as String,
      catalog: CompanyCatalogItem.fromJson(catalog),
      priceAmount: json['priceAmount'] as num?,
      availability: json['availability'] as String? ?? 'AVAILABLE',
      configuredQuantity: json['configuredQuantity'] as int?,
      reservedQuantity: json['reservedQuantity'] as int? ?? 0,
      displayOrder: json['displayOrder'] as int? ?? 0,
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }

  final String id;
  final String serviceUnitId;
  final CompanyCatalogItem catalog;
  final num? priceAmount;
  final String availability;
  final int? configuredQuantity;
  final int reservedQuantity;
  final int displayOrder;
  final String status;

  String get priceLabel {
    final price = priceAmount;
    if (price == null) {
      return 'Prix catalogue';
    }
    return price.toStringAsFixed(2);
  }
}

String? _blankToNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}
