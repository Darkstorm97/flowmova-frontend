import 'package:flowmova_frontend/src/features/client/data/company_detail_gateway.dart';
import 'package:flowmova_frontend/src/features/client/presentation/company_detail_screen.dart';
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
    expect(find.byTooltip('Creer une demande'), findsOneWidget);
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
}
