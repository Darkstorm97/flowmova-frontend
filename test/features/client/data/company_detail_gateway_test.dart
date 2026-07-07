import 'dart:async';
import 'dart:convert';

import 'package:flowmova_frontend/src/core/api/api_client.dart';
import 'package:flowmova_frontend/src/core/config/app_environment.dart';
import 'package:flowmova_frontend/src/features/client/data/company_detail_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const environment = AppEnvironment(apiBaseUrl: 'http://localhost:8080');

  test('getDetail loads company catalogs and service units', () async {
    final capturedPaths = <String>[];
    final gateway = BackendCompanyDetailGateway(
      ApiClient(
        environment: environment,
        httpClient: MockClient.streaming((request, bodyStream) async {
          capturedPaths.add(request.url.path);

          final body = switch (request.url.path) {
            '/api/companies/company-1' => {
              'id': 'company-1',
              'name': 'Cafe Flow',
              'description': 'Cafe and service queue.',
              'imageUrl': 'https://cdn.flowmova.test/companies/cafe-flow.jpg',
              'currency': 'CAD',
              'businessType': 'RESTAURANT',
              'addressLine1': '123 Flow Street',
              'addressLine2': null,
              'city': 'Montreal',
              'region': 'Quebec',
              'postalCode': 'H2X 1Y4',
              'country': 'CA',
              'status': 'ACTIVE',
            },
            '/api/companies/company-1/catalog-categories' => [
              {
                'id': 'category-1',
                'companyId': 'company-1',
                'name': 'Boissons',
                'description': 'Cafe et boissons chaudes.',
                'displayOrder': 1,
                'status': 'ACTIVE',
              },
            ],
            '/api/companies/company-1/catalogs' => [
              {
                'id': 'catalog-1',
                'companyId': 'company-1',
                'catalogCategoryId': 'category-1',
                'name': 'Cafe filtre',
                'description': 'Grand cafe chaud.',
                'imageUrl': null,
                'priceAmount': 4.5,
                'status': 'ACTIVE',
              },
            ],
            '/api/companies/company-1/service-units' => [
              {
                'id': 'service-unit-1',
                'companyId': 'company-1',
                'name': 'Comptoir principal',
                'description': 'Commandes sur place.',
                'location': 'Accueil',
                'type': 'TICKET_QUEUE',
                'status': 'OPEN',
                'ticketCreationGuardMode': 'NONE',
                'defaultLocation': null,
              },
            ],
            _ => throw StateError('Unexpected path ${request.url.path}'),
          };

          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode(body))),
            200,
          );
        }),
      ),
    );

    final result = await gateway.getDetail('company-1');

    expect(capturedPaths, [
      '/api/companies/company-1',
      '/api/companies/company-1/catalog-categories',
      '/api/companies/company-1/catalogs',
      '/api/companies/company-1/service-units',
    ]);
    expect(result.company.name, 'Cafe Flow');
    expect(result.company.addressLabel, contains('123 Flow Street'));
    expect(result.catalogCategories.single.name, 'Boissons');
    expect(result.catalogs.single.name, 'Cafe filtre');
    expect(result.catalogs.single.priceLabel, '4.50 \$');
    expect(result.serviceUnits.single.name, 'Comptoir principal');
  });
}
