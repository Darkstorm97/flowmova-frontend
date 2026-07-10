import 'dart:async';
import 'dart:convert';

import 'package:flowmova_frontend/src/core/api/api_client.dart';
import 'package:flowmova_frontend/src/core/config/app_environment.dart';
import 'package:flowmova_frontend/src/features/business/data/current_user_companies_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const environment = AppEnvironment(apiBaseUrl: 'http://localhost:8080');

  test('listCompanies gets current user companies with pagination', () async {
    late Uri capturedUrl;

    final gateway = BackendCurrentUserCompaniesGateway(
      ApiClient(
        environment: environment,
        httpClient: MockClient.streaming((request, bodyStream) async {
          capturedUrl = request.url;
          return http.StreamedResponse(
            Stream.value(
              utf8.encode(
                jsonEncode({
                  'items': [_companyJson()],
                  'page': 1,
                  'size': 10,
                  'totalItems': 22,
                  'totalPages': 3,
                }),
              ),
            ),
            200,
          );
        }),
      ),
    );

    final page = await gateway.listCompanies(page: 1, size: 10);

    expect(capturedUrl.path, '/api/users/me/companies');
    expect(capturedUrl.queryParameters['page'], '1');
    expect(capturedUrl.queryParameters['size'], '10');
    expect(capturedUrl.queryParameters['sort'], 'name,asc');
    expect(page.hasPreviousPage, isTrue);
    expect(page.hasNextPage, isTrue);
    expect(page.items.single.name, 'Cafe Flow');
    expect(page.items.single.role, 'ADMIN');
    expect(page.items.single.imageUrl, 'https://cdn.test/cafe-flow.jpg');
    expect(page.items.single.locationLabel, 'Montreal, Quebec, CA');
    expect(page.items.single.isOperationallyOpen, isTrue);
  });
}

Map<String, Object?> _companyJson() {
  return {
    'id': 'company-1',
    'name': 'Cafe Flow',
    'description': 'Comptoir rapide pour les tests.',
    'imageUrl': 'https://cdn.test/cafe-flow.jpg',
    'currency': 'CAD',
    'businessType': 'RESTAURANT',
    'addressLine1': '100 Rue Flow',
    'addressLine2': null,
    'city': 'Montreal',
    'region': 'Quebec',
    'postalCode': 'H2X 1Y4',
    'country': 'CA',
    'latitude': 45.5017,
    'longitude': -73.5673,
    'status': 'ACTIVE',
    'operationalStatus': 'OPEN',
    'role': 'ADMIN',
    'createdAt': '2026-07-07T12:00:00Z',
    'updatedAt': '2026-07-07T12:05:00Z',
  };
}
