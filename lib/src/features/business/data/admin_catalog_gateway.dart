import '../../../core/api/api_client.dart';
import '../../client/data/company_detail_gateway.dart';

abstract interface class AdminCatalogGateway {
  Future<AdminCatalogBundle> getCatalog(String companyId);

  Future<CompanyCatalogCategory> createCategory(
    String companyId,
    CatalogCategoryInput input,
  );

  Future<CompanyCatalogItem> createCatalog(
    String companyId,
    CatalogInput input,
  );

  Future<CompanyCatalogItem> updateCatalog(
    String companyId,
    String catalogId,
    CatalogInput input,
  );

  Future<CompanyCatalogItem> archiveCatalog(String companyId, String catalogId);
}

class BackendAdminCatalogGateway implements AdminCatalogGateway {
  const BackendAdminCatalogGateway(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<AdminCatalogBundle> getCatalog(String companyId) async {
    final categoriesResponse = await _apiClient.get(
      '/api/companies/$companyId/catalog-categories',
    );
    final catalogsResponse = await _apiClient.get(
      '/api/companies/$companyId/catalogs',
    );
    if (categoriesResponse is! List) {
      throw const FormatException('Invalid catalog categories response.');
    }
    if (catalogsResponse is! List) {
      throw const FormatException('Invalid catalogs response.');
    }
    return AdminCatalogBundle(
      categories: categoriesResponse
          .whereType<Map<String, dynamic>>()
          .map(CompanyCatalogCategory.fromJson)
          .toList(growable: false),
      catalogs: catalogsResponse
          .whereType<Map<String, dynamic>>()
          .map(CompanyCatalogItem.fromJson)
          .toList(growable: false),
    );
  }

  @override
  Future<CompanyCatalogCategory> createCategory(
    String companyId,
    CatalogCategoryInput input,
  ) async {
    final response = await _apiClient.post(
      '/api/companies/$companyId/catalog-categories',
      body: input.toJson(),
    );
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Invalid catalog category response.');
    }
    return CompanyCatalogCategory.fromJson(response);
  }

  @override
  Future<CompanyCatalogItem> createCatalog(
    String companyId,
    CatalogInput input,
  ) async {
    final response = await _apiClient.post(
      '/api/companies/$companyId/catalogs',
      body: input.toJson(),
    );
    return _catalogFromResponse(response);
  }

  @override
  Future<CompanyCatalogItem> updateCatalog(
    String companyId,
    String catalogId,
    CatalogInput input,
  ) async {
    final response = await _apiClient.put(
      '/api/companies/$companyId/catalogs/$catalogId',
      body: input.toJson(),
    );
    return _catalogFromResponse(response);
  }

  @override
  Future<CompanyCatalogItem> archiveCatalog(
    String companyId,
    String catalogId,
  ) async {
    final response = await _apiClient.delete(
      '/api/companies/$companyId/catalogs/$catalogId',
    );
    return _catalogFromResponse(response);
  }

  CompanyCatalogItem _catalogFromResponse(Object? response) {
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Invalid catalog response.');
    }
    return CompanyCatalogItem.fromJson(response);
  }
}

class AdminCatalogBundle {
  const AdminCatalogBundle({required this.categories, required this.catalogs});

  final List<CompanyCatalogCategory> categories;
  final List<CompanyCatalogItem> catalogs;
}

class CatalogCategoryInput {
  const CatalogCategoryInput({
    required this.name,
    this.description,
    this.displayOrder,
  });

  final String name;
  final String? description;
  final int? displayOrder;

  Map<String, Object?> toJson() {
    return {
      'name': name.trim(),
      'description': _blankToNull(description),
      'displayOrder': displayOrder,
    };
  }
}

class CatalogInput {
  const CatalogInput({
    required this.catalogCategoryId,
    required this.name,
    this.description,
    this.imageUrl,
    this.priceAmount,
  });

  final String catalogCategoryId;
  final String name;
  final String? description;
  final String? imageUrl;
  final num? priceAmount;

  Map<String, Object?> toJson() {
    return {
      'catalogCategoryId': catalogCategoryId,
      'name': name.trim(),
      'description': _blankToNull(description),
      'imageUrl': _blankToNull(imageUrl),
      'priceAmount': priceAmount,
    };
  }
}

String? _blankToNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}
