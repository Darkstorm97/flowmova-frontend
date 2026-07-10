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

  test('createCompany posts company creation payload', () async {
    late Uri capturedUrl;
    late Map<String, dynamic> capturedBody;

    final gateway = BackendCurrentUserCompaniesGateway(
      ApiClient(
        environment: environment,
        httpClient: MockClient.streaming((request, bodyStream) async {
          capturedUrl = request.url;
          capturedBody =
              jsonDecode(await utf8.decodeStream(bodyStream))
                  as Map<String, dynamic>;
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode(_companyJson()))),
            201,
          );
        }),
      ),
    );

    final company = await gateway.createCompany(
      const CreateCompanyInput(
        name: ' Cafe Flow ',
        description: '',
        imageUrl: 'https://cdn.test/cafe-flow.jpg',
        currency: 'cad',
        businessType: 'RESTAURANT',
        operationalStatus: 'OPEN',
        city: 'Montreal',
        country: 'ca',
        latitude: 45.5017,
      ),
    );

    expect(capturedUrl.path, '/api/companies');
    expect(capturedBody['name'], 'Cafe Flow');
    expect(capturedBody['description'], isNull);
    expect(capturedBody['currency'], 'CAD');
    expect(capturedBody['businessType'], 'RESTAURANT');
    expect(capturedBody['operationalStatus'], 'OPEN');
    expect(capturedBody['city'], 'Montreal');
    expect(capturedBody['country'], 'CA');
    expect(capturedBody['latitude'], 45.5017);
    expect(company.id, 'company-1');
    expect(company.role, 'ADMIN');
  });

  test('updateCompany puts company update payload', () async {
    late Uri capturedUrl;
    late Map<String, dynamic> capturedBody;

    final gateway = BackendCurrentUserCompaniesGateway(
      ApiClient(
        environment: environment,
        httpClient: MockClient.streaming((request, bodyStream) async {
          capturedUrl = request.url;
          capturedBody =
              jsonDecode(await utf8.decodeStream(bodyStream))
                  as Map<String, dynamic>;
          return http.StreamedResponse(
            Stream.value(
              utf8.encode(
                jsonEncode({
                  ..._companyJson(),
                  'name': 'Cafe Flow modifie',
                  'currency': 'XOF',
                  'operationalStatus': 'CLOSED',
                }),
              ),
            ),
            200,
          );
        }),
      ),
    );

    final company = await gateway.updateCompany(
      ' company-1 ',
      const CreateCompanyInput(
        name: ' Cafe Flow modifie ',
        description: 'Nouvelle description',
        imageUrl: 'https://cdn.test/cafe-flow.jpg',
        currency: 'xof',
        businessType: 'RESTAURANT',
        operationalStatus: 'CLOSED',
        city: 'Dakar',
        country: 'sn',
      ),
    );

    expect(capturedUrl.path, '/api/companies/company-1');
    expect(capturedBody['name'], 'Cafe Flow modifie');
    expect(capturedBody['description'], 'Nouvelle description');
    expect(capturedBody['imageUrl'], 'https://cdn.test/cafe-flow.jpg');
    expect(capturedBody['currency'], 'XOF');
    expect(capturedBody['operationalStatus'], 'CLOSED');
    expect(capturedBody['city'], 'Dakar');
    expect(capturedBody['country'], 'SN');
    expect(company.name, 'Cafe Flow modifie');
    expect(company.currency, 'XOF');
    expect(company.role, 'ADMIN');
  });

  test('uploadCompanyImage posts multipart image payload', () async {
    late Uri capturedUrl;
    late String capturedContentType;
    late String capturedBody;

    final gateway = BackendCurrentUserCompaniesGateway(
      ApiClient(
        environment: environment,
        httpClient: MockClient.streaming((request, bodyStream) async {
          capturedUrl = request.url;
          capturedContentType = request.headers['content-type'] ?? '';
          capturedBody = await utf8.decodeStream(bodyStream);
          return http.StreamedResponse(
            Stream.value(
              utf8.encode(
                jsonEncode({
                  ..._companyJson(),
                  'imageUrl':
                      'http://localhost:8080/uploads/companies/company-1/cover.png',
                }),
              ),
            ),
            200,
          );
        }),
      ),
    );

    final company = await gateway.uploadCompanyImage(
      'company-1',
      const CompanyImageUpload(
        bytes: [1, 2, 3],
        filename: 'cover.png',
        contentType: 'image/png',
      ),
    );

    expect(capturedUrl.path, '/api/companies/company-1/image');
    expect(capturedContentType, startsWith('multipart/form-data; boundary='));
    expect(capturedBody, contains('name="image"'));
    expect(capturedBody, contains('filename="cover.png"'));
    expect(capturedBody.toLowerCase(), contains('content-type: image/png'));
    expect(
      company.imageUrl,
      'http://localhost:8080/uploads/companies/company-1/cover.png',
    );
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
