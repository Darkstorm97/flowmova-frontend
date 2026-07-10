import 'dart:async';
import 'dart:convert';

import 'package:flowmova_frontend/src/core/api/api_client.dart';
import 'package:flowmova_frontend/src/core/config/app_environment.dart';
import 'package:flowmova_frontend/src/features/business/data/business_dashboard_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const environment = AppEnvironment(apiBaseUrl: 'http://localhost:8080');

  test(
    'getDashboard loads company, admin services and catalog previews',
    () async {
      final capturedUrls = <Uri>[];

      final gateway = BackendBusinessDashboardGateway(
        ApiClient(
          environment: environment,
          httpClient: MockClient.streaming((request, bodyStream) async {
            capturedUrls.add(request.url);

            final payload = switch (request.url.path) {
              '/api/companies/company-1' => _companyJson(),
              '/api/companies/company-1/admin/service-units' => {
                'items': [_serviceJson()],
                'page': 0,
                'size': 6,
                'totalItems': 3,
                'totalPages': 1,
              },
              '/api/companies/company-1/catalog-categories' => [
                _categoryJson(),
              ],
              '/api/companies/company-1/catalogs' => [_catalogJson()],
              _ => throw StateError('Unexpected path ${request.url.path}'),
            };

            return http.StreamedResponse(
              Stream.value(utf8.encode(jsonEncode(payload))),
              200,
            );
          }),
        ),
      );

      final dashboard = await gateway.getDashboard('company-1');

      expect(capturedUrls.map((url) => url.path), [
        '/api/companies/company-1',
        '/api/companies/company-1/admin/service-units',
        '/api/companies/company-1/catalog-categories',
        '/api/companies/company-1/catalogs',
      ]);
      expect(capturedUrls[1].queryParameters['page'], '0');
      expect(capturedUrls[1].queryParameters['size'], '6');
      expect(capturedUrls[1].queryParameters['sort'], 'name,asc');
      expect(dashboard.company.name, 'Cafe Flow');
      expect(dashboard.services.totalItems, 3);
      expect(dashboard.services.items.single.name, 'Comptoir');
      expect(dashboard.services.items.single.isQrOnly, isFalse);
      expect(dashboard.services.items.single.allowTicketWithoutItems, isTrue);
      expect(dashboard.services.items.single.defaultLocation?.name, 'Salle');
      expect(dashboard.catalogCategories.single.name, 'Boissons');
      expect(dashboard.catalogs.single.name, 'Latte');
    },
  );
}

Map<String, Object?> _companyJson() {
  return {
    'id': 'company-1',
    'name': 'Cafe Flow',
    'description': 'Comptoir rapide pour les tests.',
    'imageUrl': null,
    'currency': 'CAD',
    'businessType': 'RESTAURANT',
    'addressLine1': '100 Rue Flow',
    'addressLine2': null,
    'city': 'Montreal',
    'region': 'Quebec',
    'postalCode': 'H2X 1Y4',
    'country': 'CA',
    'status': 'ACTIVE',
    'operationalStatus': 'OPEN',
  };
}

Map<String, Object?> _serviceJson() {
  return {
    'id': 'service-1',
    'companyId': 'company-1',
    'name': 'Comptoir',
    'description': 'Commandes rapides.',
    'location': 'Montreal',
    'type': 'ORDER',
    'status': 'OPEN',
    'ticketCreationGuardMode': 'ALWAYS_ALLOWED',
    'creationEntryMode': 'PUBLIC_AND_QR',
    'allowTicketWithoutItems': true,
    'defaultLocation': {
      'id': 'location-1',
      'serviceUnitId': 'service-1',
      'name': 'Salle',
      'description': null,
      'type': 'ONSITE',
      'defaultLocation': true,
      'status': 'ACTIVE',
      'publicAccessSlug': 'cafe-flow-salle',
    },
  };
}

Map<String, Object?> _categoryJson() {
  return {
    'id': 'category-1',
    'companyId': 'company-1',
    'name': 'Boissons',
    'description': null,
    'displayOrder': 1,
    'status': 'ACTIVE',
  };
}

Map<String, Object?> _catalogJson() {
  return {
    'id': 'catalog-1',
    'name': 'Latte',
    'catalogCategoryId': 'category-1',
    'description': null,
    'imageUrl': null,
    'priceAmount': 4.5,
    'status': 'ACTIVE',
  };
}
