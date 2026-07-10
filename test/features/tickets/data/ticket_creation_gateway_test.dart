import 'dart:async';
import 'dart:convert';

import 'package:flowmova_frontend/src/core/api/api_client.dart';
import 'package:flowmova_frontend/src/core/config/app_environment.dart';
import 'package:flowmova_frontend/src/features/tickets/data/ticket_creation_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const environment = AppEnvironment(apiBaseUrl: 'http://localhost:8080');

  test('createTicket posts service unit ticket payload', () async {
    late Uri capturedUrl;
    late Map<String, dynamic> capturedBody;

    final gateway = BackendTicketCreationGateway(
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
                  'id': 'ticket-1',
                  'ticketNumber': 'FM-0001',
                  'accessCode': 'ABC123',
                  'guestName': 'Marc',
                  'customerPhone': '+15145550000',
                  'serviceUnitId': 'service-unit-1',
                  'locationId': 'location-2',
                  'status': 'CREATED',
                  'currency': 'CAD',
                  'totalAmount': 9.5,
                }),
              ),
            ),
            201,
          );
        }),
      ),
    );

    final result = await gateway.createTicket(
      'service-unit-1',
      const CreateTicketCommand(
        locationId: 'location-2',
        guestName: ' Marc ',
        customerPhone: '+15145550000',
        notes: ' Table 12 ',
        lines: [CreateTicketLineCommand(itemId: 'item-1', quantity: 2)],
      ),
    );

    expect(capturedUrl.path, '/api/service-units/service-unit-1/tickets');
    expect(capturedBody['locationId'], 'location-2');
    expect(capturedBody['guestName'], 'Marc');
    expect(capturedBody['notes'], 'Table 12');
    expect(capturedBody['lines'], [
      {'itemId': 'item-1', 'quantity': 2},
    ]);
    expect(result.ticketNumber, 'FM-0001');
    expect(result.accessCode, 'ABC123');
    expect(result.totalLabel, '9.50 CAD');
  });

  test(
    'createTicketFromPublicLocation posts QR location ticket payload',
    () async {
      late Uri capturedUrl;
      late Map<String, dynamic> capturedBody;

      final gateway = BackendTicketCreationGateway(
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
                    'id': 'ticket-qr-1',
                    'ticketNumber': 'FM-QR-0001',
                    'accessCode': 'QR123ABC',
                    'guestName': 'Marc',
                    'serviceUnitId': 'service-unit-1',
                    'locationId': 'location-qr',
                    'status': 'CREATED',
                    'currency': 'CAD',
                    'totalAmount': 0,
                  }),
                ),
              ),
              201,
            );
          }),
        ),
      );

      final result = await gateway.createTicketFromPublicLocation(
        'loc-public-1',
        const CreateTicketCommand(
          locationId: 'location-client-side-ignored',
          guestName: ' Marc ',
        ),
      );

      expect(capturedUrl.path, '/api/public/locations/loc-public-1/tickets');
      expect(capturedBody.containsKey('locationId'), isFalse);
      expect(capturedBody['guestName'], 'Marc');
      expect(result.ticketNumber, 'FM-QR-0001');
      expect(result.locationId, 'location-qr');
    },
  );

  test('createTicket accepts connected empty-item ticket response', () async {
    late Map<String, dynamic> capturedBody;

    final gateway = BackendTicketCreationGateway(
      ApiClient(
        environment: environment,
        httpClient: MockClient.streaming((request, bodyStream) async {
          capturedBody =
              jsonDecode(await utf8.decodeStream(bodyStream))
                  as Map<String, dynamic>;

          return http.StreamedResponse(
            Stream.value(
              utf8.encode(
                jsonEncode({
                  'id': 'ticket-empty',
                  'ticketNumber': 'FM-0002',
                  'serviceUnitId': 'service-unit-1',
                  'locationId': 'location-1',
                  'status': 'CREATED',
                  'currency': 'CAD',
                  'totalAmount': 0,
                  'lines': const [],
                  'createdAt': '2026-07-10T15:00:00Z',
                }),
              ),
            ),
            201,
          );
        }),
      ),
    );

    final result = await gateway.createTicket(
      'service-unit-1',
      const CreateTicketCommand(locationId: 'location-1'),
    );

    expect(capturedBody['locationId'], 'location-1');
    expect(capturedBody['lines'], isEmpty);
    expect(result.ticketNumber, 'FM-0002');
    expect(result.accessCode, isNull);
    expect(result.totalLabel, '0.00 CAD');
  });

  test('createTicket accepts minimal ticket response', () async {
    final gateway = BackendTicketCreationGateway(
      ApiClient(
        environment: environment,
        httpClient: MockClient.streaming((request, bodyStream) async {
          return http.StreamedResponse(
            Stream.value(
              utf8.encode(
                jsonEncode({'id': 'ticket-empty', 'ticketNumber': 'FM-0003'}),
              ),
            ),
            201,
          );
        }),
      ),
    );

    final result = await gateway.createTicket(
      'service-unit-1',
      const CreateTicketCommand(locationId: 'location-1'),
    );

    expect(result.ticketNumber, 'FM-0003');
    expect(result.status, 'CREATED');
    expect(result.totalLabel, '0.00 ');
  });
}
