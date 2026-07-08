import 'package:flowmova_frontend/src/features/client/data/company_detail_gateway.dart';
import 'package:flowmova_frontend/src/features/client/data/public_location_gateway.dart';
import 'package:flowmova_frontend/src/features/client/presentation/public_location_screen.dart';
import 'package:flowmova_frontend/src/features/tickets/data/recent_ticket_storage.dart';
import 'package:flowmova_frontend/src/features/tickets/data/ticket_creation_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('public QR screen creates an on-site ticket from initial slug', (
    tester,
  ) async {
    final recentTicketStorage = InMemoryRecentTicketStorage();
    final ticketGateway = _FakeTicketCreationGateway();

    await tester.pumpWidget(
      MaterialApp(
        home: PublicLocationScreen(
          initialSlug: 'loc-1',
          gateway: const _FakePublicLocationGateway(),
          ticketCreationGateway: ticketGateway,
          recentTicketStorage: recentTicketStorage,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Commande sur place'), findsOneWidget);
    expect(find.text('Cafe Flow'), findsOneWidget);
    expect(find.text('Comptoir QR'), findsOneWidget);
    expect(find.text('Table 4'), findsOneWidget);

    await tester.tap(find.text('Cafe filtre'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Nom'), 'Marc');
    await tester.ensureVisible(find.text('Creer ma commande'));
    await tester.tap(find.text('Creer ma commande'));
    await tester.pumpAndSettle();

    expect(ticketGateway.publicSlug, 'loc-1');
    expect(ticketGateway.command?.guestName, 'Marc');
    expect(ticketGateway.command?.lines.single.itemId, 'item-1');
    expect(find.text('Commande creee'), findsOneWidget);
    expect(find.text('FM-QR-0001'), findsOneWidget);
    expect(find.text('QR123ABC'), findsOneWidget);

    final recentTickets = await recentTicketStorage.load();
    expect(recentTickets, hasLength(1));
    expect(recentTickets.single.ticketNumber, 'FM-QR-0001');
    expect(recentTickets.single.companyName, 'Cafe Flow');
    expect(recentTickets.single.locationName, 'Table 4');
    expect(recentTickets.single.items.single.name, 'Cafe filtre');
  });

  testWidgets('public QR screen accepts a pasted QR link', (tester) async {
    final gateway = _CapturingPublicLocationGateway();

    await tester.pumpWidget(
      MaterialApp(
        home: PublicLocationScreen(
          gateway: gateway,
          ticketCreationGateway: _FakeTicketCreationGateway(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Code ou lien QR'),
      'https://flowmova.test/locations/public?slug=loc-42',
    );
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    expect(gateway.requestedSlug, 'loc-42');
    expect(find.text('Cafe Flow'), findsOneWidget);
  });
}

class _FakePublicLocationGateway implements PublicLocationGateway {
  const _FakePublicLocationGateway();

  @override
  Future<PublicLocationAccess> getAccess(String publicAccessSlug) async {
    return _publicLocationAccess();
  }
}

class _CapturingPublicLocationGateway implements PublicLocationGateway {
  String? requestedSlug;

  @override
  Future<PublicLocationAccess> getAccess(String publicAccessSlug) async {
    requestedSlug = publicAccessSlug;
    return _publicLocationAccess();
  }
}

class _FakeTicketCreationGateway implements TicketCreationGateway {
  String? publicSlug;
  CreateTicketCommand? command;

  @override
  Future<TicketCreationResult> createTicket(
    String serviceUnitId,
    CreateTicketCommand command,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<TicketCreationResult> createTicketFromPublicLocation(
    String publicAccessSlug,
    CreateTicketCommand command,
  ) async {
    publicSlug = publicAccessSlug;
    this.command = command;

    return const TicketCreationResult(
      id: 'ticket-1',
      ticketNumber: 'FM-QR-0001',
      accessCode: 'QR123ABC',
      guestName: 'Marc',
      serviceUnitId: 'service-unit-1',
      locationId: 'location-1',
      status: 'CREATED',
      currency: 'CAD',
      totalAmount: 4.5,
    );
  }
}

PublicLocationAccess _publicLocationAccess() {
  return const PublicLocationAccess(
    company: CompanyDetail(
      id: 'company-1',
      name: 'Cafe Flow',
      description: 'Cafe QR.',
      currency: 'CAD',
      businessType: 'RESTAURANT',
      city: 'Montreal',
      region: 'Quebec',
      country: 'CA',
      status: 'ACTIVE',
    ),
    serviceUnit: CompanyServiceUnitItem(
      id: 'service-unit-1',
      name: 'Comptoir QR',
      type: 'TICKET_QUEUE',
      status: 'OPEN',
      ticketCreationGuardMode: 'AUTHENTICATED_OR_GUEST_RECENT_ONE_OPEN_TICKET',
      creationEntryMode: 'QR_ONLY',
      location: 'Salle principale',
    ),
    location: CompanyServiceUnitLocation(
      id: 'location-1',
      serviceUnitId: 'service-unit-1',
      name: 'Table 4',
      type: 'TABLE',
      defaultLocation: false,
      publicAccessSlug: 'loc-1',
      status: 'ACTIVE',
    ),
    items: [
      CompanyServiceUnitAvailableItem(
        id: 'item-1',
        priceAmount: 4.5,
        availability: 'AVAILABLE',
        status: 'ACTIVE',
        catalog: CompanyCatalogItem(
          id: 'catalog-1',
          name: 'Cafe filtre',
          catalogCategoryId: 'category-1',
          priceAmount: 4.5,
          status: 'ACTIVE',
        ),
      ),
    ],
  );
}
