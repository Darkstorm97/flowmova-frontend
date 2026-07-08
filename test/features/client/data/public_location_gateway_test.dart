import 'dart:async';
import 'dart:convert';

import 'package:flowmova_frontend/src/core/api/api_client.dart';
import 'package:flowmova_frontend/src/core/config/app_environment.dart';
import 'package:flowmova_frontend/src/features/client/data/public_location_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const environment = AppEnvironment(apiBaseUrl: 'http://localhost:8080');

  test('getAccess loads public QR location context', () async {
    late Uri capturedUrl;

    final gateway = BackendPublicLocationGateway(
      ApiClient(
        environment: environment,
        httpClient: MockClient.streaming((request, bodyStream) async {
          capturedUrl = request.url;

          return http.StreamedResponse(
            Stream.value(
              utf8.encode(
                jsonEncode({
                  'company': {
                    'id': 'company-1',
                    'name': 'Cafe Flow',
                    'description': 'Cafe QR.',
                    'imageUrl': null,
                    'currency': 'CAD',
                    'businessType': 'RESTAURANT',
                    'status': 'ACTIVE',
                    'operationalStatus': 'OPEN',
                    'city': 'Montreal',
                    'region': 'Quebec',
                    'country': 'CA',
                  },
                  'serviceUnit': {
                    'id': 'service-unit-1',
                    'companyId': 'company-1',
                    'name': 'Comptoir QR',
                    'description': 'Commande sur place.',
                    'location': 'Salle principale',
                    'type': 'TICKET_QUEUE',
                    'status': 'OPEN',
                    'ticketCreationGuardMode':
                        'AUTHENTICATED_OR_GUEST_RECENT_ONE_OPEN_TICKET',
                    'creationEntryMode': 'QR_ONLY',
                  },
                  'location': {
                    'id': 'location-1',
                    'serviceUnitId': 'service-unit-1',
                    'name': 'Table 4',
                    'type': 'TABLE',
                    'defaultLocation': false,
                    'publicAccessSlug': 'loc-1',
                    'status': 'ACTIVE',
                  },
                  'items': [
                    {
                      'id': 'item-1',
                      'priceAmount': 4.5,
                      'availability': 'AVAILABLE',
                      'status': 'ACTIVE',
                      'catalog': {
                        'id': 'catalog-1',
                        'name': 'Cafe filtre',
                        'catalogCategoryId': 'category-1',
                        'priceAmount': 4.5,
                        'status': 'ACTIVE',
                      },
                    },
                  ],
                }),
              ),
            ),
            200,
          );
        }),
      ),
    );

    final result = await gateway.getAccess('loc-1');

    expect(capturedUrl.path, '/api/public/locations/loc-1');
    expect(result.company.name, 'Cafe Flow');
    expect(result.serviceUnit.name, 'Comptoir QR');
    expect(result.serviceUnit.requiresQrCode, isTrue);
    expect(result.location.publicAccessSlug, 'loc-1');
    expect(result.items.single.catalog.name, 'Cafe filtre');
    expect(result.canCreateTicket, isTrue);
  });
}
