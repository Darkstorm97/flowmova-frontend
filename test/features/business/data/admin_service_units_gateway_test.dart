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
    expect(capturedBody['allowTicketWithoutItems'], isTrue);
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
        allowTicketWithoutItems: false,
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
    expect(capturedBody['allowTicketWithoutItems'], isFalse);
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

  test('listTickets and changeTicketStatus use admin ticket endpoints', () async {
    final capturedUrls = <Uri>[];
    late Map<String, dynamic> capturedBody;

    final gateway = BackendAdminServiceUnitsGateway(
      ApiClient(
        environment: environment,
        httpClient: MockClient.streaming((request, bodyStream) async {
          capturedUrls.add(request.url);
          if (request.method == 'PATCH') {
            capturedBody =
                jsonDecode(await utf8.decodeStream(bodyStream))
                    as Map<String, dynamic>;
            return _jsonResponse(_ticketJson(status: 'RECEIVED'));
          }
          return _jsonResponse({
            'items': [_ticketJson(status: 'CREATED')],
            'page': 0,
            'size': 20,
            'totalItems': 1,
            'totalPages': 1,
          });
        }),
      ),
    );

    final page = await gateway.listTickets(
      'company-1',
      'service-1',
      status: 'CREATED',
      ticketNumber: ' T-1 ',
      locationId: 'location-1',
    );
    final ticket = await gateway.changeTicketStatus(
      'company-1',
      'service-1',
      'ticket-1',
      'RECEIVED',
    );

    expect(
      capturedUrls[0].path,
      '/api/companies/company-1/admin/service-units/service-1/tickets',
    );
    expect(capturedUrls[0].queryParameters['sort'], 'createdAt,asc');
    expect(capturedUrls[0].queryParameters['status'], 'CREATED');
    expect(capturedUrls[0].queryParameters['ticketNumber'], 'T-1');
    expect(capturedUrls[0].queryParameters['locationId'], 'location-1');
    expect(page.items.single.ticketNumber, 'T-0001');
    expect(
      capturedUrls[1].path,
      '/api/companies/company-1/admin/service-units/service-1/tickets/ticket-1/status',
    );
    expect(capturedBody, {'status': 'RECEIVED'});
    expect(ticket.status, 'RECEIVED');
  });

  test('listCompanyTickets calls company admin ticket endpoint', () async {
    late Uri capturedUrl;

    final gateway = BackendAdminServiceUnitsGateway(
      ApiClient(
        environment: environment,
        httpClient: MockClient.streaming((request, bodyStream) async {
          capturedUrl = request.url;
          return _jsonResponse({
            'items': [_ticketJson(status: 'CREATED')],
            'page': 0,
            'size': 50,
            'totalItems': 1,
            'totalPages': 1,
          });
        }),
      ),
    );

    final page = await gateway.listCompanyTickets(
      'company-1',
      serviceUnitId: 'service-1',
      status: 'CREATED',
      ticketNumber: ' T-1 ',
    );

    expect(capturedUrl.path, '/api/companies/company-1/admin/tickets');
    expect(capturedUrl.queryParameters['page'], '0');
    expect(capturedUrl.queryParameters['size'], '50');
    expect(capturedUrl.queryParameters['sort'], 'createdAt,asc');
    expect(capturedUrl.queryParameters['serviceUnitId'], 'service-1');
    expect(capturedUrl.queryParameters['status'], 'CREATED');
    expect(capturedUrl.queryParameters['ticketNumber'], 'T-1');
    expect(page.items.single.ticketNumber, 'T-0001');
  });

  test(
    'listItems createItem and updateItem use admin item endpoints',
    () async {
      final capturedUrls = <Uri>[];
      final capturedBodies = <Map<String, dynamic>>[];

      final gateway = BackendAdminServiceUnitsGateway(
        ApiClient(
          environment: environment,
          httpClient: MockClient.streaming((request, bodyStream) async {
            capturedUrls.add(request.url);
            if (request.method == 'POST' || request.method == 'PUT') {
              capturedBodies.add(
                jsonDecode(await utf8.decodeStream(bodyStream))
                    as Map<String, dynamic>,
              );
              return _jsonResponse(
                _itemJson(),
                statusCode: request.method == 'POST' ? 201 : 200,
              );
            }
            return _jsonResponse([_itemJson()]);
          }),
        ),
      );

      final items = await gateway.listItems('company-1', 'service-1');
      final created = await gateway.createItem(
        'company-1',
        'service-1',
        const ServiceUnitItemInput(
          catalogId: 'catalog-1',
          availability: 'AVAILABLE',
          configuredQuantity: 10,
          displayOrder: 2,
        ),
      );
      final updated = await gateway.updateItem(
        'company-1',
        'service-1',
        'item-1',
        const ServiceUnitItemInput(
          catalogId: 'catalog-1',
          priceAmount: 4.25,
          availability: 'UNAVAILABLE',
          configuredQuantity: 0,
          displayOrder: 3,
        ),
      );

      expect(
        capturedUrls[0].path,
        '/api/companies/company-1/admin/service-units/service-1/items',
      );
      expect(items.single.catalog.name, 'Cafe filtre');
      expect(
        capturedUrls[1].path,
        '/api/companies/company-1/admin/service-units/service-1/items',
      );
      expect(capturedBodies[0]['catalogId'], 'catalog-1');
      expect(created.id, 'item-1');
      expect(
        capturedUrls[2].path,
        '/api/companies/company-1/admin/service-units/service-1/items/item-1',
      );
      expect(capturedBodies[1].containsKey('catalogId'), isFalse);
      expect(capturedBodies[1]['availability'], 'UNAVAILABLE');
      expect(updated.catalog.name, 'Cafe filtre');
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
    'allowTicketWithoutItems': true,
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

Map<String, Object?> _ticketJson({required String status}) {
  return {
    'id': 'ticket-1',
    'ticketNumber': 'T-0001',
    'userId': 'user-1',
    'companyId': 'company-1',
    'companyName': 'Cafe Flow',
    'serviceUnitId': 'service-1',
    'serviceUnitName': 'File principale',
    'locationId': 'location-1',
    'locationName': 'Principal',
    'locationDefault': true,
    'status': status,
    'currency': 'CAD',
    'totalAmount': 0,
    'lines': const [],
    'createdAt': '2026-07-10T12:00:00Z',
  };
}

Map<String, Object?> _itemJson() {
  return {
    'id': 'item-1',
    'serviceUnitId': 'service-1',
    'catalog': {
      'id': 'catalog-1',
      'companyId': 'company-1',
      'catalogCategoryId': 'category-1',
      'name': 'Cafe filtre',
      'description': null,
      'imageUrl': null,
      'priceAmount': 4.5,
      'status': 'ACTIVE',
    },
    'priceAmount': 4.5,
    'availability': 'AVAILABLE',
    'configuredQuantity': 10,
    'reservedQuantity': 0,
    'displayOrder': 1,
    'status': 'ACTIVE',
  };
}
