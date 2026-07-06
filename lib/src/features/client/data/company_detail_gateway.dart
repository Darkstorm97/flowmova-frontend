import '../../../core/api/api_client.dart';
import 'company_search_gateway.dart';

abstract interface class CompanyDetailGateway {
  Future<CompanyDetailBundle> getDetail(String companyId);
}

class BackendCompanyDetailGateway implements CompanyDetailGateway {
  const BackendCompanyDetailGateway(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<CompanyDetailBundle> getDetail(String companyId) async {
    final companyResponse = await _apiClient.get('/api/companies/$companyId');
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

    if (serviceUnitsResponse is! List) {
      throw const FormatException(
        'Invalid company service units response payload.',
      );
    }

    return CompanyDetailBundle(
      company: CompanyDetail.fromJson(companyResponse),
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
}

class CompanyDetailBundle {
  const CompanyDetailBundle({
    required this.company,
    required this.catalogs,
    required this.serviceUnits,
  });

  final CompanyDetail company;
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
    );
  }
}

class CompanyCatalogItem {
  const CompanyCatalogItem({
    required this.id,
    required this.name,
    required this.status,
    this.description,
    this.imageUrl,
    this.priceAmount,
  });

  factory CompanyCatalogItem.fromJson(Map<String, dynamic> json) {
    return CompanyCatalogItem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      priceAmount: json['priceAmount'] as num?,
      status: json['status'] as String,
    );
  }

  final String id;
  final String name;
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
    );
  }

  final String id;
  final String name;
  final String? description;
  final String? location;
  final String type;
  final String status;
  final String ticketCreationGuardMode;
}
