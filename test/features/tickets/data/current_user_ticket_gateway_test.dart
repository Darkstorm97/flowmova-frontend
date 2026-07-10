import 'dart:async';
import 'dart:convert';

import 'package:flowmova_frontend/src/core/api/api_client.dart';
import 'package:flowmova_frontend/src/core/config/app_environment.dart';
import 'package:flowmova_frontend/src/features/tickets/data/current_user_ticket_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const environment = AppEnvironment(apiBaseUrl: 'http://localhost:8080');

  test('listTickets gets current user tickets with pagination', () async {
    late Uri capturedUrl;

    final gateway = BackendCurrentUserTicketGateway(
      ApiClient(
        environment: environment,
        httpClient: MockClient.streaming((request, bodyStream) async {
          capturedUrl = request.url;
          return http.StreamedResponse(
            Stream.value(
              utf8.encode(
                jsonEncode({
                  'items': [_ticketJson(status: 'RECEIVED')],
                  'page': 0,
                  'size': 20,
                  'totalItems': 1,
                  'totalPages': 1,
                }),
              ),
            ),
            200,
          );
        }),
      ),
    );

    final page = await gateway.listTickets(
      page: 0,
      size: 20,
      status: 'RECEIVED',
      ticketNumber: ' FM-0001 ',
    );

    expect(capturedUrl.path, '/api/users/me/tickets');
    expect(capturedUrl.queryParameters['page'], '0');
    expect(capturedUrl.queryParameters['size'], '20');
    expect(capturedUrl.queryParameters['status'], 'RECEIVED');
    expect(capturedUrl.queryParameters['ticketNumber'], 'FM-0001');
    expect(page.items.single.ticketNumber, 'FM-0001');
    expect(page.items.single.totalLabel, '12.50 CAD');
  });

  test('cancelTicket patches current user cancel endpoint', () async {
    late Uri capturedUrl;

    final gateway = BackendCurrentUserTicketGateway(
      ApiClient(
        environment: environment,
        httpClient: MockClient.streaming((request, bodyStream) async {
          capturedUrl = request.url;
          return _ticketResponse(status: 'CANCELLED');
        }),
      ),
    );

    final ticket = await gateway.cancelTicket(' ticket-1 ');

    expect(capturedUrl.path, '/api/users/me/tickets/ticket-1/cancel');
    expect(ticket.status, 'CANCELLED');
  });

  test(
    'confirmTicketTreatment patches current user confirmation endpoint',
    () async {
      late Uri capturedUrl;

      final gateway = BackendCurrentUserTicketGateway(
        ApiClient(
          environment: environment,
          httpClient: MockClient.streaming((request, bodyStream) async {
            capturedUrl = request.url;
            return _ticketResponse(status: 'CUSTOMER_CONFIRMED');
          }),
        ),
      );

      final ticket = await gateway.confirmTicketTreatment('ticket-1');

      expect(
        capturedUrl.path,
        '/api/users/me/tickets/ticket-1/confirm-treatment',
      );
      expect(ticket.status, 'CUSTOMER_CONFIRMED');
    },
  );
}

http.StreamedResponse _ticketResponse({required String status}) {
  return http.StreamedResponse(
    Stream.value(utf8.encode(jsonEncode(_ticketJson(status: status)))),
    200,
  );
}

Map<String, Object?> _ticketJson({required String status}) {
  return {
    'id': 'ticket-1',
    'ticketNumber': 'FM-0001',
    'userId': 'user-1',
    'customerPhone': '+15145550000',
    'serviceUnitId': 'service-1',
    'locationId': 'location-1',
    'status': status,
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
  };
}
