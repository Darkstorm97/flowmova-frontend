import '../../../core/api/api_client.dart';
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

  BusinessServiceUnit _serviceUnitFromResponse(Object? response) {
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Invalid service unit response.');
    }
    return BusinessServiceUnit.fromJson(response);
  }
}

class ServiceUnitInput {
  const ServiceUnitInput({
    required this.name,
    required this.ticketCreationGuardMode,
    required this.creationEntryMode,
    this.description,
    this.location,
  });

  final String name;
  final String? description;
  final String? location;
  final String ticketCreationGuardMode;
  final String creationEntryMode;

  Map<String, Object?> toJson({bool includeType = false}) {
    return {
      'name': name.trim(),
      'description': _blankToNull(description),
      'location': _blankToNull(location),
      if (includeType) 'type': 'TICKET_QUEUE',
      'ticketCreationGuardMode': ticketCreationGuardMode,
      'creationEntryMode': creationEntryMode,
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

String? _blankToNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}
