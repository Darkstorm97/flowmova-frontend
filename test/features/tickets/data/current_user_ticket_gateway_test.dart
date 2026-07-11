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
    expect(page.items.single.guestName, 'Alice Client');
    expect(page.items.single.companyName, 'Cafe Flow');
    expect(page.items.single.serviceUnitName, 'Comptoir');
    expect(page.items.single.locationName, 'Accueil');
    expect(page.items.single.locationDefault, isTrue);
    expect(page.items.single.totalLabel, '12.50 CAD');
    expect(page.items.single.lines.single.itemName, 'Latte glace');
    expect(
      page.items.single.lines.single.itemImageUrl,
      'https://cdn.test/latte.jpg',
    );
  });

  test(
    'listTickets tolerates empty-item tickets with optional fields omitted',
    () async {
      final gateway = BackendCurrentUserTicketGateway(
        ApiClient(
          environment: environment,
          httpClient: MockClient.streaming((request, bodyStream) async {
            return http.StreamedResponse(
              Stream.value(
                utf8.encode(
                  jsonEncode({
                    'items': [
                      {
                        'id': 'ticket-empty',
                        'ticketNumber': 'FM-0002',
                        'companyId': 'company-1',
                        'companyName': 'Cafe Flow',
                        'serviceUnitId': 'service-1',
                        'serviceUnitName': 'Comptoir',
                        'locationId': 'location-1',
                        'locationName': 'Accueil',
                        'status': 'CREATED',
                        'currency': 'CAD',
                        'totalAmount': 0,
                        'lines': const [],
                        'createdAt': '2026-07-07T12:00:00Z',
                      },
                    ],
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

      final page = await gateway.listTickets();

      expect(page.items.single.ticketNumber, 'FM-0002');
      expect(page.items.single.userId, '');
      expect(page.items.single.lines, isEmpty);
      expect(page.items.single.totalLabel, '0.00 CAD');
    },
  );

  test('listTickets tolerates missing page counters', () async {
    final gateway = BackendCurrentUserTicketGateway(
      ApiClient(
        environment: environment,
        httpClient: MockClient.streaming((request, bodyStream) async {
          return http.StreamedResponse(
            Stream.value(
              utf8.encode(
                jsonEncode({
                  'items': [_ticketJson(status: 'CREATED')],
                }),
              ),
            ),
            200,
          );
        }),
      ),
    );

    final page = await gateway.listTickets();

    expect(page.page, 0);
    expect(page.size, 1);
    expect(page.totalItems, 1);
    expect(page.totalPages, 1);
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
    'guestName': 'Alice Client',
    'customerPhone': '+15145550000',
    'companyId': 'company-1',
    'companyName': 'Cafe Flow',
    'serviceUnitId': 'service-1',
    'serviceUnitName': 'Comptoir',
    'locationId': 'location-1',
    'locationName': 'Accueil',
    'locationDefault': true,
    'status': status,
    'currency': 'CAD',
    'totalAmount': 12.5,
    'lines': [
      {
        'id': 'line-1',
        'itemId': 'item-1',
        'itemName': 'Latte glace',
        'itemImageUrl': 'https://cdn.test/latte.jpg',
        'quantity': 2,
        'unitPriceAmount': 6.25,
        'lineTotalAmount': 12.5,
      },
    ],
    'createdAt': '2026-07-07T12:00:00Z',
    'updatedAt': '2026-07-07T12:05:00Z',
  };
}
