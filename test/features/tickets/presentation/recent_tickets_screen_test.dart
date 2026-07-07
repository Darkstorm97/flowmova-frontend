import 'package:flowmova_frontend/src/features/tickets/data/recent_ticket_storage.dart';
import 'package:flowmova_frontend/src/features/tickets/presentation/recent_tickets_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('recent tickets screen shows and clears local tickets', (
    tester,
  ) async {
    final storage = InMemoryRecentTicketStorage([
      RecentTicketEntry(
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
        totalLabel: '0.00 CAD',
        items: const [
          RecentTicketItemEntry(
            itemId: 'item-1',
            name: 'Latte glace',
            quantity: 1,
          ),
        ],
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RecentTicketsScreen(recentTicketStorage: storage)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tickets recents'), findsOneWidget);
    expect(find.text('Recents sur cet appareil'), findsOneWidget);
    expect(find.text('FM-0001'), findsOneWidget);
    expect(find.textContaining('Latte glace x1'), findsOneWidget);

    await tester.tap(find.text('Vider'));
    await tester.pumpAndSettle();

    expect(
      find.text('Aucun ticket recent sur cet appareil pour le moment.'),
      findsOneWidget,
    );
  });
}
