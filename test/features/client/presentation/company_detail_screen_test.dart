import 'package:flowmova_frontend/src/features/client/data/company_detail_gateway.dart';
import 'package:flowmova_frontend/src/features/client/presentation/company_detail_screen.dart';
import 'package:flowmova_frontend/src/features/tickets/data/ticket_creation_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('company detail shows public company services and catalogs', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CompanyDetailScreen(
          companyId: 'company-1',
          detailGateway: const _FakeCompanyDetailGateway(),
          ticketCreationGateway: const _FakeTicketCreationGateway(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Cafe Flow'), findsOneWidget);
    expect(find.text('Restauration'), findsOneWidget);
    expect(find.text('Services disponibles'), findsOneWidget);
    expect(find.text('Comptoir principal'), findsOneWidget);
    expect(find.text('Catalogue'), findsOneWidget);
    expect(find.text('Cafe filtre'), findsOneWidget);
    expect(find.text('4.50 \$'), findsOneWidget);
    expect(find.text('Creer une demande'), findsOneWidget);
  });

  testWidgets('company detail creates a ticket from the guided sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CompanyDetailScreen(
          companyId: 'company-1',
          detailGateway: const _FakeCompanyDetailGateway(),
          ticketCreationGateway: const _FakeTicketCreationGateway(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Creer une demande'));
    await tester.tap(find.text('Creer une demande'));
    await tester.pumpAndSettle();

    expect(find.text('Emplacement'), findsOneWidget);
    expect(find.text('Accueil'), findsWidgets);

    await tester.enterText(find.byType(TextField).first, 'Marc');
    await tester.ensureVisible(find.text('Creer mon ticket'));
    await tester.tap(find.text('Creer mon ticket'));
    await tester.pumpAndSettle();

    expect(find.text('Ticket cree'), findsOneWidget);
    expect(find.text('FM-0001'), findsOneWidget);
    expect(find.text('ABC123'), findsOneWidget);
  });
}

class _FakeCompanyDetailGateway implements CompanyDetailGateway {
  const _FakeCompanyDetailGateway();

  @override
  Future<CompanyDetailBundle> getDetail(String companyId) async {
    return const CompanyDetailBundle(
      company: CompanyDetail(
        id: 'company-1',
        name: 'Cafe Flow',
        description: 'Cafe and service queue.',
        currency: 'CAD',
        businessType: 'RESTAURANT',
        city: 'Montreal',
        region: 'Quebec',
        country: 'CA',
        status: 'ACTIVE',
      ),
      catalogs: [
        CompanyCatalogItem(
          id: 'catalog-1',
          name: 'Cafe filtre',
          description: 'Grand cafe chaud.',
          priceAmount: 4.5,
          status: 'ACTIVE',
        ),
      ],
      serviceUnits: [
        CompanyServiceUnitItem(
          id: 'service-unit-1',
          name: 'Comptoir principal',
          location: 'Accueil',
          type: 'TICKET_QUEUE',
          status: 'OPEN',
          ticketCreationGuardMode: 'NONE',
        ),
      ],
    );
  }

  @override
  Future<CompanyServiceUnitDetail> getServiceUnitDetail(
    String companyId,
    String serviceUnitId,
  ) async {
    return const CompanyServiceUnitDetail(
      id: 'service-unit-1',
      companyId: 'company-1',
      name: 'Comptoir principal',
      location: 'Accueil',
      type: 'TICKET_QUEUE',
      status: 'OPEN',
      ticketCreationGuardMode: 'NONE',
      locations: [
        CompanyServiceUnitLocation(
          id: 'location-1',
          serviceUnitId: 'service-unit-1',
          name: 'Accueil',
          type: 'DEFAULT',
          defaultLocation: true,
          status: 'ACTIVE',
        ),
      ],
      items: [],
    );
  }
}

class _FakeTicketCreationGateway implements TicketCreationGateway {
  const _FakeTicketCreationGateway();

  @override
  Future<TicketCreationResult> createTicket(
    String serviceUnitId,
    CreateTicketCommand command,
  ) async {
    return TicketCreationResult(
      id: 'ticket-1',
      ticketNumber: 'FM-0001',
      accessCode: 'ABC123',
      guestName: command.guestName,
      serviceUnitId: serviceUnitId,
      locationId: command.locationId,
      status: 'CREATED',
      currency: 'CAD',
      totalAmount: 0,
    );
  }
}
