import '../../../core/api/api_client.dart';

abstract interface class CurrentUserCompaniesGateway {
  Future<CurrentUserCompanyPage> listCompanies({int page = 0, int size = 10});

  Future<CurrentUserCompany> createCompany(CreateCompanyInput input);
}

class BackendCurrentUserCompaniesGateway
    implements CurrentUserCompaniesGateway {
  const BackendCurrentUserCompaniesGateway(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<CurrentUserCompanyPage> listCompanies({
    int page = 0,
    int size = 10,
  }) async {
    final response = await _apiClient.get(
      '/api/users/me/companies',
      queryParameters: {'page': page, 'size': size, 'sort': 'name,asc'},
    );

    if (response is! Map<String, dynamic>) {
      throw const FormatException('Invalid current user companies payload.');
    }

    return CurrentUserCompanyPage.fromJson(response);
  }

  @override
  Future<CurrentUserCompany> createCompany(CreateCompanyInput input) async {
    final response = await _apiClient.post(
      '/api/companies',
      body: input.toJson(),
    );

    if (response is! Map<String, dynamic>) {
      throw const FormatException('Invalid created company payload.');
    }

    return CurrentUserCompany.fromJson({...response, 'role': 'ADMIN'});
  }
}

class CreateCompanyInput {
  const CreateCompanyInput({
    required this.name,
    required this.currency,
    required this.businessType,
    required this.operationalStatus,
    this.description,
    this.imageUrl,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.region,
    this.postalCode,
    this.country,
    this.latitude,
    this.longitude,
  });

  final String name;
  final String? description;
  final String? imageUrl;
  final String currency;
  final String businessType;
  final String operationalStatus;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? region;
  final String? postalCode;
  final String? country;
  final double? latitude;
  final double? longitude;

  Map<String, Object?> toJson() {
    return {
      'name': name.trim(),
      'description': _blankToNull(description),
      'imageUrl': _blankToNull(imageUrl),
      'currency': currency.trim().toUpperCase(),
      'businessType': businessType,
      'operationalStatus': operationalStatus,
      'addressLine1': _blankToNull(addressLine1),
      'addressLine2': _blankToNull(addressLine2),
      'city': _blankToNull(city),
      'region': _blankToNull(region),
      'postalCode': _blankToNull(postalCode),
      'country': _blankToNull(country)?.toUpperCase(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

class CurrentUserCompanyPage {
  const CurrentUserCompanyPage({
    required this.items,
    required this.page,
    required this.size,
    required this.totalItems,
    required this.totalPages,
  });

  factory CurrentUserCompanyPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is! List) {
      throw const FormatException('Invalid current user companies items.');
    }

    return CurrentUserCompanyPage(
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(CurrentUserCompany.fromJson)
          .toList(growable: false),
      page: json['page'] as int,
      size: json['size'] as int,
      totalItems: json['totalItems'] as int,
      totalPages: json['totalPages'] as int,
    );
  }

  final List<CurrentUserCompany> items;
  final int page;
  final int size;
  final int totalItems;
  final int totalPages;

  bool get hasPreviousPage => page > 0;

  bool get hasNextPage => totalPages > 0 && page < totalPages - 1;
}

class CurrentUserCompany {
  const CurrentUserCompany({
    required this.id,
    required this.name,
    required this.currency,
    required this.businessType,
    required this.status,
    required this.operationalStatus,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.imageUrl,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.region,
    this.postalCode,
    this.country,
  });

  factory CurrentUserCompany.fromJson(Map<String, dynamic> json) {
    return CurrentUserCompany(
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
      operationalStatus: json['operationalStatus'] as String,
      role: json['role'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
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
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isOperationallyOpen => operationalStatus == 'OPEN';

  String get locationLabel {
    final parts = [city, region, country]
        .where((part) => part != null && part.trim().isNotEmpty)
        .cast<String>()
        .toList(growable: false);
    return parts.isEmpty ? 'Adresse a confirmer' : parts.join(', ');
  }
}
