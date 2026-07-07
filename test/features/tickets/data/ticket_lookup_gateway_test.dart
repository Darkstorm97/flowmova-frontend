import 'dart:async';
import 'dart:convert';

import 'package:flowmova_frontend/src/core/api/api_client.dart';
import 'package:flowmova_frontend/src/core/config/app_environment.dart';
import 'package:flowmova_frontend/src/features/tickets/data/ticket_lookup_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const environment = AppEnvironment(apiBaseUrl: 'http://localhost:8080');

  test('getGuestTicket posts ticket number and access code', () async {
    late Uri capturedUrl;
    late Map<String, dynamic> capturedBody;

    final gateway = BackendTicketLookupGateway(
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
                  'ticketNumber': 'FM-0001',
                  'guestName': 'Marc',
                  'customerPhone': '+15145550000',
                  'serviceUnitId': 'service-1',
                  'locationId': 'location-1',
                  'status': 'RECEIVED',
                  'currency': 'CAD',
                  'totalAmount': 12.5,
                  'lines': [
                    {
                      'id': 'line-1',
                      'itemId': 'item-1',
                      'quantity': 2,
                      'unitPriceAmount': 6.25,
                      'lineTotalAmount': 12.5,
                    },
                  ],
                  'createdAt': '2026-07-07T12:00:00Z',
                  'updatedAt': '2026-07-07T12:05:00Z',
                }),
              ),
            ),
            200,
          );
        }),
      ),
    );

    final ticket = await gateway.getGuestTicket(
      ticketNumber: ' FM-0001 ',
      accessCode: ' ABC123 ',
    );

    expect(capturedUrl.path, '/api/tickets/guest-access');
    expect(capturedBody, {'ticketNumber': 'FM-0001', 'accessCode': 'ABC123'});
    expect(ticket.ticketNumber, 'FM-0001');
    expect(ticket.status, 'RECEIVED');
    expect(ticket.totalLabel, '12.50 CAD');
    expect(ticket.lines.single.itemId, 'item-1');
  });
}
