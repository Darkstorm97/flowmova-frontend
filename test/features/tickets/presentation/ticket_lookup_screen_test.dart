import 'package:flowmova_frontend/src/features/tickets/data/recent_ticket_storage.dart';
import 'package:flowmova_frontend/src/features/tickets/data/ticket_lookup_gateway.dart';
import 'package:flowmova_frontend/src/features/tickets/presentation/ticket_lookup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens a recent ticket and refreshes local status', (
    tester,
  ) async {
    final recentTicket = RecentTicketEntry(
      id: 'ticket-1',
      ticketNumber: 'FM-0001',
      accessCode: 'ABC123',
      serviceUnitId: 'service-1',
      locationId: 'location-1',
      companyId: 'company-1',
      status: 'CREATED',
      createdAt: DateTime.utc(2026, 7, 7),
      companyName: 'Cafe Flow',
      serviceUnitName: 'Comptoir principal',
      locationName: 'Accueil',
      totalLabel: '6.25 CAD',
      items: const [
        RecentTicketItemEntry(
          itemId: 'item-1',
          name: 'Latte glace',
          quantity: 1,
        ),
      ],
    );
    final storage = InMemoryRecentTicketStorage([recentTicket]);
    final gateway = _FakeTicketLookupGateway(
      PublicTicket(
        ticketNumber: 'FM-0001',
        guestName: 'Marc',
        serviceUnitId: 'service-1',
        locationId: 'location-1',
        status: 'RECEIVED',
        currency: 'CAD',
        totalAmount: 12.5,
        lines: [
          PublicTicketLine(
            id: 'line-1',
            itemId: 'item-1',
            quantity: 2,
            unitPriceAmount: 6.25,
            lineTotalAmount: 12.5,
          ),
        ],
        createdAt: DateTime.utc(2026, 7, 7),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TicketLookupScreen(
            arguments: TicketLookupArguments(recentTicket: recentTicket),
            lookupGateway: gateway,
            recentTicketStorage: storage,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(gateway.ticketNumber, 'FM-0001');
    expect(gateway.accessCode, 'ABC123');
    expect(find.text('RECEIVED'), findsOneWidget);
    expect(find.text('Comptoir principal'), findsOneWidget);
    expect(find.text('Accueil'), findsOneWidget);
    expect(find.text('Latte glace x2'), findsOneWidget);
    expect(find.text('12.50 CAD'), findsOneWidget);

    final refreshedTickets = await storage.load();
    expect(refreshedTickets.single.status, 'RECEIVED');
    expect(refreshedTickets.single.totalLabel, '12.50 CAD');
  });
}

class _FakeTicketLookupGateway implements TicketLookupGateway {
  _FakeTicketLookupGateway(this.ticket);

  final PublicTicket ticket;
  String? ticketNumber;
  String? accessCode;

  @override
  Future<PublicTicket> getGuestTicket({
    required String ticketNumber,
    required String accessCode,
  }) async {
    this.ticketNumber = ticketNumber;
    this.accessCode = accessCode;
    return ticket;
  }
}
