import 'dart:async';
import 'dart:convert';

import 'package:flowmova_frontend/src/core/api/api_client.dart';
import 'package:flowmova_frontend/src/core/config/app_environment.dart';
import 'package:flowmova_frontend/src/features/business/data/admin_catalog_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const environment = AppEnvironment(apiBaseUrl: 'http://localhost:8080');

  test('getCatalog loads categories and catalogs', () async {
    final capturedUrls = <Uri>[];

    final gateway = BackendAdminCatalogGateway(
      ApiClient(
        environment: environment,
        httpClient: MockClient.streaming((request, bodyStream) async {
          capturedUrls.add(request.url);
          if (request.url.path.endsWith('/catalog-categories')) {
            return _jsonResponse([_categoryJson()]);
          }
          return _jsonResponse([_catalogJson()]);
        }),
      ),
    );

    final bundle = await gateway.getCatalog('company-1');

    expect(capturedUrls[0].path, '/api/companies/company-1/catalog-categories');
    expect(capturedUrls[1].path, '/api/companies/company-1/catalogs');
    expect(bundle.categories.single.name, 'Boissons');
    expect(bundle.catalogs.single.name, 'Cafe filtre');
  });

  test('createCategory posts catalog category payload', () async {
    late Uri capturedUrl;
    late Map<String, dynamic> capturedBody;

    final gateway = BackendAdminCatalogGateway(
      ApiClient(
        environment: environment,
        httpClient: MockClient.streaming((request, bodyStream) async {
          capturedUrl = request.url;
          capturedBody =
              jsonDecode(await utf8.decodeStream(bodyStream))
                  as Map<String, dynamic>;
          return _jsonResponse(_categoryJson(), statusCode: 201);
        }),
      ),
    );

    final category = await gateway.createCategory(
      'company-1',
      const CatalogCategoryInput(
        name: ' Boissons ',
        description: '',
        displayOrder: 2,
      ),
    );

    expect(capturedUrl.path, '/api/companies/company-1/catalog-categories');
    expect(capturedBody['name'], 'Boissons');
    expect(capturedBody['description'], isNull);
    expect(capturedBody['displayOrder'], 2);
    expect(category.id, 'category-1');
  });

  test('create update and archive catalog call catalog endpoints', () async {
    final capturedUrls = <Uri>[];
    final capturedBodies = <Map<String, dynamic>>[];

    final gateway = BackendAdminCatalogGateway(
      ApiClient(
        environment: environment,
        httpClient: MockClient.streaming((request, bodyStream) async {
          capturedUrls.add(request.url);
          if (request.method == 'POST' || request.method == 'PUT') {
            capturedBodies.add(
              jsonDecode(await utf8.decodeStream(bodyStream))
                  as Map<String, dynamic>,
            );
          }
          return _jsonResponse(
            _catalogJson(
              status: request.method == 'DELETE' ? 'ARCHIVED' : 'ACTIVE',
            ),
            statusCode: request.method == 'POST' ? 201 : 200,
          );
        }),
      ),
    );

    final created = await gateway.createCatalog(
      'company-1',
      const CatalogInput(
        catalogCategoryId: 'category-1',
        name: ' Cafe filtre ',
        description: ' Chaud ',
        imageUrl: '',
        priceAmount: 4.5,
      ),
    );
    final updated = await gateway.updateCatalog(
      'company-1',
      'catalog-1',
      const CatalogInput(
        catalogCategoryId: 'category-1',
        name: 'Cafe filtre',
        priceAmount: 4.75,
      ),
    );
    final archived = await gateway.archiveCatalog('company-1', 'catalog-1');

    expect(capturedUrls[0].path, '/api/companies/company-1/catalogs');
    expect(capturedBodies[0]['catalogCategoryId'], 'category-1');
    expect(capturedBodies[0]['name'], 'Cafe filtre');
    expect(capturedBodies[0]['description'], 'Chaud');
    expect(capturedBodies[0]['imageUrl'], isNull);
    expect(capturedBodies[0]['priceAmount'], 4.5);
    expect(created.name, 'Cafe filtre');
    expect(capturedUrls[1].path, '/api/companies/company-1/catalogs/catalog-1');
    expect(capturedBodies[1]['priceAmount'], 4.75);
    expect(updated.status, 'ACTIVE');
    expect(capturedUrls[2].path, '/api/companies/company-1/catalogs/catalog-1');
    expect(archived.status, 'ARCHIVED');
  });
}

http.StreamedResponse _jsonResponse(Object payload, {int statusCode = 200}) {
  return http.StreamedResponse(
    Stream.value(utf8.encode(jsonEncode(payload))),
    statusCode,
  );
}

Map<String, Object?> _categoryJson() {
  return {
    'id': 'category-1',
    'companyId': 'company-1',
    'name': 'Boissons',
    'description': 'Categorie chaude',
    'displayOrder': 1,
    'status': 'ACTIVE',
  };
}

Map<String, Object?> _catalogJson({String status = 'ACTIVE'}) {
  return {
    'id': 'catalog-1',
    'companyId': 'company-1',
    'catalogCategoryId': 'category-1',
    'name': 'Cafe filtre',
    'description': 'Cafe chaud',
    'imageUrl': null,
    'priceAmount': 4.5,
    'status': status,
  };
}
