import '../../../core/api/api_client.dart';

abstract interface class CompanySearchGateway {
  Future<CompanySearchPage> search(CompanySearchQuery query);
}

class BackendCompanySearchGateway implements CompanySearchGateway {
  const BackendCompanySearchGateway(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<CompanySearchPage> search(CompanySearchQuery query) async {
    final response = await _apiClient.get(
      '/api/companies',
      queryParameters: query.toQueryParameters(),
    );

    if (response is! Map<String, dynamic>) {
      throw const FormatException('Invalid companies search response payload.');
    }

    return CompanySearchPage.fromJson(response);
  }
}

class CompanySearchQuery {
  const CompanySearchQuery({
    this.text,
    this.businessType,
    this.city,
    this.region,
    this.country,
    this.page = 0,
    this.size = 10,
  });

  final String? text;
  final String? businessType;
  final String? city;
  final String? region;
  final String? country;
  final int page;
  final int size;

  CompanySearchQuery copyWith({
    String? text,
    String? businessType,
    String? city,
    String? region,
    String? country,
    int? page,
    int? size,
  }) {
    return CompanySearchQuery(
      text: text ?? this.text,
      businessType: businessType ?? this.businessType,
      city: city ?? this.city,
      region: region ?? this.region,
      country: country ?? this.country,
      page: page ?? this.page,
      size: size ?? this.size,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    return {
      if (_hasText(text)) 'q': text!.trim(),
      if (_hasText(businessType)) 'businessType': businessType!.trim(),
      if (_hasText(city)) 'city': city!.trim(),
      if (_hasText(region)) 'region': region!.trim(),
      if (_hasText(country)) 'country': country!.trim(),
      'page': page,
      'size': size,
      'sort': 'name,asc',
    };
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
}

class CompanySearchPage {
  const CompanySearchPage({
    required this.items,
    required this.page,
    required this.size,
    required this.totalItems,
    required this.totalPages,
  });

  factory CompanySearchPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is! List) {
      throw const FormatException('Invalid companies items payload.');
    }

    return CompanySearchPage(
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(CompanySummary.fromJson)
          .toList(growable: false),
      page: json['page'] as int,
      size: json['size'] as int,
      totalItems: json['totalItems'] as int,
      totalPages: json['totalPages'] as int,
    );
  }

  final List<CompanySummary> items;
  final int page;
  final int size;
  final int totalItems;
  final int totalPages;

  bool get hasPreviousPage => page > 0;

  bool get hasNextPage => totalPages > 0 && page < totalPages - 1;
}

class CompanySummary {
  const CompanySummary({
    required this.id,
    required this.name,
    required this.currency,
    required this.businessType,
    required this.status,
    this.description,
    this.city,
    this.region,
    this.country,
  });

  factory CompanySummary.fromJson(Map<String, dynamic> json) {
    return CompanySummary(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      currency: json['currency'] as String,
      businessType: json['businessType'] as String,
      city: json['city'] as String?,
      region: json['region'] as String?,
      country: json['country'] as String?,
      status: json['status'] as String,
    );
  }

  final String id;
  final String name;
  final String? description;
  final String currency;
  final String businessType;
  final String? city;
  final String? region;
  final String? country;
  final String status;

  String get locationLabel {
    final parts = [city, region, country]
        .where((part) => part != null && part.trim().isNotEmpty)
        .cast<String>()
        .toList(growable: false);
    return parts.isEmpty ? 'Adresse a confirmer' : parts.join(', ');
  }
}
