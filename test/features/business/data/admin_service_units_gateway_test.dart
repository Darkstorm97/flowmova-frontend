import 'dart:async';
import 'dart:convert';

import 'package:flowmova_frontend/src/core/api/api_client.dart';
import 'package:flowmova_frontend/src/core/config/app_environment.dart';
import 'package:flowmova_frontend/src/features/business/data/admin_service_units_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const environment = AppEnvironment(apiBaseUrl: 'http://localhost:8080');

  test('listServiceUnits calls admin paginated endpoint', () async {
    late Uri capturedUrl;

    final gateway = BackendAdminServiceUnitsGateway(
      ApiClient(
        environment: environment,
        httpClient: MockClient.streaming((request, bodyStream) async {
          capturedUrl = request.url;
          return _jsonResponse({
            'items': [_serviceJson()],
            'page': 0,
            'size': 20,
            'totalItems': 1,
            'totalPages': 1,
          });
        }),
      ),
    );

    final page = await gateway.listServiceUnits('company-1', status: 'OPEN');

    expect(capturedUrl.path, '/api/companies/company-1/admin/service-units');
    expect(capturedUrl.queryParameters['page'], '0');
    expect(capturedUrl.queryParameters['size'], '20');
    expect(capturedUrl.queryParameters['sort'], 'name,asc');
    expect(capturedUrl.queryParameters['status'], 'OPEN');
    expect(page.items.single.name, 'File principale');
  });

  test('createServiceUnit posts service unit payload', () async {
    late Uri capturedUrl;
    late Map<String, dynamic> capturedBody;

    final gateway = BackendAdminServiceUnitsGateway(
      ApiClient(
        environment: environment,
        httpClient: MockClient.streaming((request, bodyStream) async {
          capturedUrl = request.url;
          capturedBody =
              jsonDecode(await utf8.decodeStream(bodyStream))
                  as Map<String, dynamic>;
          return _jsonResponse(_serviceJson(), statusCode: 201);
        }),
      ),
    );

    final service = await gateway.createServiceUnit(
      'company-1',
      const ServiceUnitInput(
        name: ' File principale ',
        location: ' Hall ',
        ticketCreationGuardMode: 'NONE',
        creationEntryMode: 'PUBLIC_AND_QR',
      ),
    );

    expect(capturedUrl.path, '/api/companies/company-1/service-units');
    expect(capturedBody['name'], 'File principale');
    expect(capturedBody['location'], 'Hall');
    expect(capturedBody['type'], 'TICKET_QUEUE');
    expect(capturedBody['ticketCreationGuardMode'], 'NONE');
    expect(capturedBody['creationEntryMode'], 'PUBLIC_AND_QR');
    expect(service.id, 'service-1');
  });

  test('updateServiceUnit puts admin service unit payload', () async {
    late Uri capturedUrl;
    late Map<String, dynamic> capturedBody;

    final gateway = BackendAdminServiceUnitsGateway(
      ApiClient(
        environment: environment,
        httpClient: MockClient.streaming((request, bodyStream) async {
          capturedUrl = request.url;
          capturedBody =
              jsonDecode(await utf8.decodeStream(bodyStream))
                  as Map<String, dynamic>;
          return _jsonResponse({..._serviceJson(), 'name': 'File modifiee'});
        }),
      ),
    );

    final service = await gateway.updateServiceUnit(
      'company-1',
      'service-1',
      const ServiceUnitInput(
        name: 'File modifiee',
        description: '',
        ticketCreationGuardMode: 'AUTHENTICATED_ONLY_ONE_OPEN_TICKET',
        creationEntryMode: 'QR_ONLY',
      ),
    );

    expect(
      capturedUrl.path,
      '/api/companies/company-1/admin/service-units/service-1',
    );
    expect(capturedBody['name'], 'File modifiee');
    expect(capturedBody['description'], isNull);
    expect(
      capturedBody['ticketCreationGuardMode'],
      'AUTHENTICATED_ONLY_ONE_OPEN_TICKET',
    );
    expect(capturedBody['creationEntryMode'], 'QR_ONLY');
    expect(service.name, 'File modifiee');
  });

  test(
    'listLocations and createLocation use admin location endpoints',
    () async {
      final capturedUrls = <Uri>[];

      final gateway = BackendAdminServiceUnitsGateway(
        ApiClient(
          environment: environment,
          httpClient: MockClient.streaming((request, bodyStream) async {
            capturedUrls.add(request.url);
            if (request.method == 'POST') {
              return _jsonResponse(
                _locationJson(name: 'Table 12'),
                statusCode: 201,
              );
            }
            return _jsonResponse({
              'items': [_locationJson()],
              'page': 0,
              'size': 20,
              'totalItems': 1,
              'totalPages': 1,
            });
          }),
        ),
      );

      final page = await gateway.listLocations('company-1', 'service-1');
      final location = await gateway.createLocation(
        'company-1',
        'service-1',
        const ServiceUnitLocationInput(name: 'Table 12'),
      );

      expect(
        capturedUrls[0].path,
        '/api/companies/company-1/admin/service-units/service-1/locations',
      );
      expect(capturedUrls[0].queryParameters['sort'], 'name,asc');
      expect(page.items.single.name, 'Principal');
      expect(location.name, 'Table 12');
    },
  );
}

http.StreamedResponse _jsonResponse(Object payload, {int statusCode = 200}) {
  return http.StreamedResponse(
    Stream.value(utf8.encode(jsonEncode(payload))),
    statusCode,
  );
}

Map<String, Object?> _serviceJson() {
  return {
    'id': 'service-1',
    'companyId': 'company-1',
    'name': 'File principale',
    'description': 'Accueil client',
    'location': 'Hall',
    'type': 'TICKET_QUEUE',
    'status': 'OPEN',
    'ticketCreationGuardMode': 'NONE',
    'creationEntryMode': 'PUBLIC_AND_QR',
    'defaultLocation': _locationJson(),
  };
}

Map<String, Object?> _locationJson({String name = 'Principal'}) {
  return {
    'id': 'location-1',
    'serviceUnitId': 'service-1',
    'name': name,
    'description': null,
    'type': 'DEFAULT',
    'defaultLocation': true,
    'publicAccessSlug': 'loc-public',
    'publicUrl': 'http://localhost:8080/public/locations/loc-public',
    'status': 'ACTIVE',
  };
}
