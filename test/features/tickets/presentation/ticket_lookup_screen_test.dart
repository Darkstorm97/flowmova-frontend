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
    expect(find.text('Recu'), findsAtLeastNWidgets(1));
    expect(find.text('Comptoir principal'), findsOneWidget);
    expect(find.text('Accueil'), findsOneWidget);
    expect(find.text('Latte glace'), findsOneWidget);
    expect(find.text('x2'), findsOneWidget);
    expect(find.text('12.50 CAD'), findsOneWidget);

    final refreshedTickets = await storage.load();
    expect(refreshedTickets.single.status, 'RECEIVED');
    expect(refreshedTickets.single.totalLabel, '12.50 CAD');
  });

  testWidgets('guest ticket actions update status and local recent ticket', (
    tester,
  ) async {
    final recentTicket = RecentTicketEntry(
      id: 'ticket-1',
      ticketNumber: 'FM-0002',
      accessCode: 'DEF456',
      serviceUnitId: 'service-1',
      locationId: 'location-1',
      companyId: 'company-1',
      status: 'TREATED',
      createdAt: DateTime.utc(2026, 7, 7),
      companyName: 'Cafe Flow',
      serviceUnitName: 'Comptoir principal',
      locationName: 'Accueil',
      totalLabel: '6.25 CAD',
    );
    final storage = InMemoryRecentTicketStorage([recentTicket]);
    final gateway = _ActionTicketLookupGateway();

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

    expect(find.text('Traite'), findsAtLeastNWidgets(1));
    await tester.ensureVisible(find.text('Confirmer le traitement'));
    await tester.tap(find.text('Confirmer le traitement'));
    await tester.pumpAndSettle();

    expect(gateway.confirmed, isTrue);
    expect(find.text('Confirme'), findsAtLeastNWidgets(1));
    expect(
      find.text('Le traitement du ticket a ete confirme.'),
      findsOneWidget,
    );

    final refreshedTickets = await storage.load();
    expect(refreshedTickets.single.status, 'CUSTOMER_CONFIRMED');
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

  @override
  Future<PublicTicket> cancelGuestTicket({
    required String ticketNumber,
    required String accessCode,
  }) async {
    return ticket;
  }

  @override
  Future<PublicTicket> confirmGuestTicketTreatment({
    required String ticketNumber,
    required String accessCode,
  }) async {
    return ticket;
  }
}

class _ActionTicketLookupGateway implements TicketLookupGateway {
  bool confirmed = false;

  @override
  Future<PublicTicket> getGuestTicket({
    required String ticketNumber,
    required String accessCode,
  }) async {
    return _ticket(status: 'TREATED');
  }

  @override
  Future<PublicTicket> cancelGuestTicket({
    required String ticketNumber,
    required String accessCode,
  }) async {
    return _ticket(status: 'CANCELLED');
  }

  @override
  Future<PublicTicket> confirmGuestTicketTreatment({
    required String ticketNumber,
    required String accessCode,
  }) async {
    confirmed = true;
    return _ticket(status: 'CUSTOMER_CONFIRMED');
  }

  PublicTicket _ticket({required String status}) {
    return PublicTicket(
      ticketNumber: 'FM-0002',
      guestName: 'Marc',
      serviceUnitId: 'service-1',
      locationId: 'location-1',
      status: status,
      currency: 'CAD',
      totalAmount: 6.25,
      lines: const [],
      createdAt: DateTime.utc(2026, 7, 7),
      updatedAt: DateTime.utc(2026, 7, 7, 12, 5),
    );
  }
}
