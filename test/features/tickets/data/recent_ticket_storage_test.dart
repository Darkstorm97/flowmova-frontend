import 'package:flowmova_frontend/src/features/tickets/data/recent_ticket_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'shared preferences recent ticket storage saves loads and clears',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final storage = SharedPreferencesRecentTicketStorage(preferences);

      await storage.save(
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
              quantity: 2,
            ),
          ],
        ),
      );

      final tickets = await storage.load();

      expect(tickets, hasLength(1));
      expect(tickets.single.ticketNumber, 'FM-0001');
      expect(tickets.single.accessCode, 'ABC123');
      expect(tickets.single.items.single.name, 'Latte glace');

      await storage.clear();

      expect(await storage.load(), isEmpty);
    },
  );

  test('recent ticket storage keeps only five latest tickets', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final storage = SharedPreferencesRecentTicketStorage(preferences);

    for (var index = 1; index <= 6; index++) {
      await storage.save(_recentTicket(index));
    }

    final tickets = await storage.load();

    expect(tickets, hasLength(5));
    expect(tickets.first.ticketNumber, 'FM-0006');
    expect(tickets.last.ticketNumber, 'FM-0002');
    expect(tickets.any((ticket) => ticket.ticketNumber == 'FM-0001'), isFalse);
  });
}

RecentTicketEntry _recentTicket(int index) {
  final suffix = index.toString().padLeft(4, '0');
  return RecentTicketEntry(
    id: 'ticket-$index',
    ticketNumber: 'FM-$suffix',
    accessCode: 'ABC$index',
    serviceUnitId: 'service-1',
    locationId: 'location-1',
    companyId: 'company-1',
    status: 'CREATED',
    createdAt: DateTime.utc(2026, 7, index),
    companyName: 'Cafe Flow',
    serviceUnitName: 'Comptoir principal',
    locationName: 'Accueil',
    totalLabel: '0.00 CAD',
  );
}
