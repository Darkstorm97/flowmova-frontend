import 'dart:convert';

import 'package:flowmova_frontend/src/core/session/auth_session_controller.dart';
import 'package:flowmova_frontend/src/core/session/session_scope.dart';
import 'package:flowmova_frontend/src/features/client/data/company_detail_gateway.dart';
import 'package:flowmova_frontend/src/features/client/presentation/company_detail_screen.dart';
import 'package:flowmova_frontend/src/features/tickets/data/recent_ticket_storage.dart';
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
    expect(find.text('Ouvert'), findsOneWidget);
    expect(find.text('Services disponibles'), findsOneWidget);
    expect(find.text('Comptoir principal'), findsWidgets);
    expect(find.text('Catalogue'), findsOneWidget);
    expect(find.text('Tout'), findsOneWidget);
    expect(find.text('Boissons'), findsOneWidget);
    expect(find.text('Cafe filtre'), findsOneWidget);
    expect(find.text('4.50 \$'), findsOneWidget);
    expect(find.text('Creer une commande'), findsOneWidget);
  });

  testWidgets('company detail disables order creation when company is closed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CompanyDetailScreen(
          companyId: 'company-1',
          detailGateway: const _ClosedCompanyDetailGateway(),
          ticketCreationGateway: const _FakeTicketCreationGateway(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Ferme'), findsOneWidget);
    expect(
      find.text('Cette entreprise n accepte pas de commandes pour le moment.'),
      findsOneWidget,
    );
    expect(find.text('Entreprise fermee'), findsOneWidget);
    expect(find.text('Creer une commande'), findsNothing);
  });

  testWidgets(
    'company detail blocks QR only services from standard order flow',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CompanyDetailScreen(
            companyId: 'company-1',
            detailGateway: const _QrOnlyCompanyDetailGateway(),
            ticketCreationGateway: const _FakeTicketCreationGateway(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Comptoir QR'), findsOneWidget);
      expect(find.textContaining('QR seulement'), findsOneWidget);
      expect(find.text('QR code requis'), findsOneWidget);
      expect(find.text('Creer une commande'), findsNothing);
    },
  );

  testWidgets('company detail filters catalogs by search', (tester) async {
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
    await tester.enterText(
      find.widgetWithText(TextField, 'Rechercher dans le catalogue'),
      'sandwich',
    );
    await tester.pumpAndSettle();

    expect(find.text('Sandwich matin'), findsOneWidget);
    expect(find.text('Cafe filtre'), findsNothing);
  });

  testWidgets('company detail creates a ticket from the guided sheet', (
    tester,
  ) async {
    final recentTicketStorage = InMemoryRecentTicketStorage();

    await tester.pumpWidget(
      MaterialApp(
        home: CompanyDetailScreen(
          companyId: 'company-1',
          detailGateway: const _FakeCompanyDetailGateway(),
          ticketCreationGateway: const _FakeTicketCreationGateway(),
          recentTicketStorage: recentTicketStorage,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Creer une commande'));
    await tester.tap(find.text('Creer une commande'));
    await tester.pumpAndSettle();

    expect(find.text('Emplacement'), findsOneWidget);
    expect(find.text('Accueil'), findsWidgets);
    expect(find.widgetWithText(TextButton, 'Modifier'), findsNothing);

    await tester.enterText(find.widgetWithText(TextField, 'Nom'), 'Marc');
    await tester.ensureVisible(find.text('Creer mon ticket'));
    await tester.tap(find.text('Creer mon ticket'));
    await tester.pumpAndSettle();

    expect(find.text('Ticket cree'), findsOneWidget);
    expect(find.text('FM-0001'), findsOneWidget);
    expect(find.text('ABC123'), findsOneWidget);
    expect(find.text('Comptoir principal'), findsWidgets);
    expect(find.text('Accueil'), findsWidgets);
    expect(find.textContaining('Conservez ce code'), findsOneWidget);

    final recentTickets = await recentTicketStorage.load();
    expect(recentTickets, hasLength(1));
    expect(recentTickets.single.ticketNumber, 'FM-0001');
    expect(recentTickets.single.serviceUnitName, 'Comptoir principal');
    expect(recentTickets.single.locationName, 'Accueil');
  });

  testWidgets('connected user creates ticket without name or item', (
    tester,
  ) async {
    final sessionController = AuthSessionController.inMemory();
    await sessionController.authenticate(_jwt());
    final ticketGateway = _CapturingTicketCreationGateway();

    await tester.pumpWidget(
      SessionScope(
        controller: sessionController,
        child: MaterialApp(
          home: CompanyDetailScreen(
            companyId: 'company-1',
            detailGateway: const _FakeCompanyDetailGateway(),
            ticketCreationGateway: ticketGateway,
            recentTicketStorage: InMemoryRecentTicketStorage(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Creer une commande'));
    await tester.tap(find.text('Creer une commande'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Nom'), findsNothing);
    await tester.ensureVisible(find.text('Creer mon ticket'));
    await tester.tap(find.text('Creer mon ticket'));
    await tester.pumpAndSettle();

    expect(find.text('Ticket cree'), findsOneWidget);
    expect(ticketGateway.lastCommand?.guestName, isNull);
    expect(ticketGateway.lastCommand?.lines, isEmpty);
  });

  testWidgets(
    'company detail blocks empty item selection when service requires items',
    (tester) async {
      final ticketGateway = _CapturingTicketCreationGateway();

      await tester.pumpWidget(
        MaterialApp(
          home: CompanyDetailScreen(
            companyId: 'company-1',
            detailGateway: const _RequiresItemsCompanyDetailGateway(),
            ticketCreationGateway: ticketGateway,
            recentTicketStorage: InMemoryRecentTicketStorage(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Creer une commande'));
      await tester.tap(find.text('Creer une commande'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Nom'), 'Marc');
      await tester.ensureVisible(find.text('Creer mon ticket'));
      await tester.tap(find.text('Creer mon ticket'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Ce service exige au moins un article pour creer une commande.',
        ),
        findsOneWidget,
      );
      expect(ticketGateway.lastCommand, isNull);
    },
  );

  testWidgets('company detail searches and selects optional ticket items', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CompanyDetailScreen(
          companyId: 'company-1',
          detailGateway: const _RichCompanyDetailGateway(),
          ticketCreationGateway: const _FakeTicketCreationGateway(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Creer une commande'));
    await tester.tap(find.text('Creer une commande'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Choisir'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Rechercher un article'),
      'latte',
    );
    await tester.pumpAndSettle();

    expect(find.text('Latte glace'), findsOneWidget);

    await tester.tap(find.text('Latte glace'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Valider (1)'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Latte glace x1'), findsOneWidget);
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
      catalogCategories: [
        CompanyCatalogCategory(
          id: 'category-1',
          companyId: 'company-1',
          name: 'Boissons',
          displayOrder: 1,
          status: 'ACTIVE',
        ),
        CompanyCatalogCategory(
          id: 'category-2',
          companyId: 'company-1',
          name: 'Repas',
          displayOrder: 2,
          status: 'ACTIVE',
        ),
      ],
      catalogs: [
        CompanyCatalogItem(
          id: 'catalog-1',
          name: 'Cafe filtre',
          catalogCategoryId: 'category-1',
          description: 'Grand cafe chaud.',
          priceAmount: 4.5,
          status: 'ACTIVE',
        ),
        CompanyCatalogItem(
          id: 'catalog-2',
          name: 'Sandwich matin',
          catalogCategoryId: 'category-2',
          description: 'Pain grille et oeufs.',
          priceAmount: 8.25,
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

  @override
  Future<TicketCreationResult> createTicketFromPublicLocation(
    String publicAccessSlug,
    CreateTicketCommand command,
  ) async {
    return TicketCreationResult(
      id: 'ticket-qr-1',
      ticketNumber: 'FM-QR-0001',
      accessCode: 'QR123',
      guestName: command.guestName,
      serviceUnitId: 'service-unit-1',
      locationId: command.locationId,
      status: 'CREATED',
      currency: 'CAD',
      totalAmount: 0,
    );
  }
}

class _CapturingTicketCreationGateway implements TicketCreationGateway {
  CreateTicketCommand? lastCommand;

  @override
  Future<TicketCreationResult> createTicket(
    String serviceUnitId,
    CreateTicketCommand command,
  ) async {
    lastCommand = command;
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

  @override
  Future<TicketCreationResult> createTicketFromPublicLocation(
    String publicAccessSlug,
    CreateTicketCommand command,
  ) {
    throw UnimplementedError();
  }
}

class _QrOnlyCompanyDetailGateway implements CompanyDetailGateway {
  const _QrOnlyCompanyDetailGateway();

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
      catalogCategories: [],
      catalogs: [],
      serviceUnits: [
        CompanyServiceUnitItem(
          id: 'service-unit-qr',
          name: 'Comptoir QR',
          location: 'Salle',
          type: 'TICKET_QUEUE',
          status: 'OPEN',
          ticketCreationGuardMode: 'NONE',
          creationEntryMode: 'QR_ONLY',
        ),
      ],
    );
  }

  @override
  Future<CompanyServiceUnitDetail> getServiceUnitDetail(
    String companyId,
    String serviceUnitId,
  ) async {
    throw UnimplementedError();
  }
}

class _ClosedCompanyDetailGateway implements CompanyDetailGateway {
  const _ClosedCompanyDetailGateway();

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
        operationalStatus: 'CLOSED',
      ),
      catalogCategories: [],
      catalogs: [],
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
    throw UnimplementedError();
  }
}

class _RichCompanyDetailGateway implements CompanyDetailGateway {
  const _RichCompanyDetailGateway();

  @override
  Future<CompanyDetailBundle> getDetail(String companyId) async {
    return const _FakeCompanyDetailGateway().getDetail(companyId);
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
        CompanyServiceUnitLocation(
          id: 'location-2',
          serviceUnitId: 'service-unit-1',
          name: 'Terrasse',
          type: 'TABLE',
          defaultLocation: false,
          status: 'ACTIVE',
        ),
      ],
      items: [
        CompanyServiceUnitAvailableItem(
          id: 'item-1',
          catalog: CompanyCatalogItem(
            id: 'catalog-3',
            name: 'Latte glace',
            catalogCategoryId: 'category-1',
            description: 'Cafe froid au lait.',
            imageUrl: 'https://cdn.flowmova.test/catalogs/latte-glace.jpg',
            priceAmount: 5.75,
            status: 'ACTIVE',
          ),
          priceAmount: 5.75,
          availability: 'AVAILABLE',
          status: 'ACTIVE',
        ),
        CompanyServiceUnitAvailableItem(
          id: 'item-2',
          catalog: CompanyCatalogItem(
            id: 'catalog-2',
            name: 'Sandwich matin',
            catalogCategoryId: 'category-2',
            description: 'Pain grille et oeufs.',
            imageUrl: 'https://cdn.flowmova.test/catalogs/sandwich.jpg',
            priceAmount: 8.25,
            status: 'ACTIVE',
          ),
          priceAmount: 8.25,
          availability: 'AVAILABLE',
          status: 'ACTIVE',
        ),
      ],
    );
  }
}

class _RequiresItemsCompanyDetailGateway extends _FakeCompanyDetailGateway {
  const _RequiresItemsCompanyDetailGateway();

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
      allowTicketWithoutItems: false,
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

String _jwt() {
  final expiresAt = DateTime.now().toUtc().add(const Duration(hours: 1));
  final header = _encode({'alg': 'none', 'typ': 'JWT'});
  final payload = _encode({'exp': expiresAt.millisecondsSinceEpoch ~/ 1000});
  return '$header.$payload.signature';
}

String _encode(Map<String, dynamic> json) {
  return base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
}
