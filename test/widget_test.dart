import 'package:flowmova_frontend/src/app/flow_mova_app.dart';
import 'package:flowmova_frontend/src/core/session/session_scope.dart';
import 'package:flowmova_frontend/src/features/client/data/company_search_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final companySearchGateway = _FakeCompanySearchGateway(
    const CompanySearchPage(
      items: [
        CompanySummary(
          id: 'company-1',
          name: 'Cafe Flow',
          description: 'Service rapide et demandes simples.',
          currency: 'CAD',
          businessType: 'RESTAURANT',
          city: 'Montreal',
          region: 'Quebec',
          country: 'CA',
          status: 'ACTIVE',
        ),
      ],
      page: 0,
      size: 10,
      totalItems: 1,
      totalPages: 1,
    ),
  );

  testWidgets('FlowMova app starts on the client space', (tester) async {
    await tester.pumpWidget(
      FlowMovaApp(companySearchGateway: companySearchGateway),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trouvez une entreprise'), findsOneWidget);
    expect(find.text('Accueil'), findsAtLeastNWidgets(1));
    expect(find.text('Tickets'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Entreprise'), findsOneWidget);
    expect(find.text('Cafe Flow'), findsOneWidget);
    expect(find.byTooltip('Scanner un QR code'), findsOneWidget);
    expect(find.text('Consulter un ticket'), findsNothing);
  });

  testWidgets('main navigation opens tickets profile and business spaces', (
    tester,
  ) async {
    await tester.pumpWidget(
      FlowMovaApp(companySearchGateway: companySearchGateway),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tickets'));
    await tester.pumpAndSettle();
    expect(find.text('Mes tickets'), findsOneWidget);
    expect(find.text('Recents sur cet appareil'), findsOneWidget);
    expect(find.text('Voir un ticket avec le code'), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Vous n etes pas connecte'), findsOneWidget);

    await tester.tap(find.text('Entreprise'));
    await tester.pumpAndSettle();
    expect(find.text('Administration entreprise'), findsOneWidget);
  });

  testWidgets('unknown route shows a clean not found page', (tester) async {
    await tester.pumpWidget(
      FlowMovaApp(companySearchGateway: companySearchGateway),
    );
    await tester.pumpAndSettle();

    Navigator.of(
      tester.element(find.text('Trouvez une entreprise')),
    ).pushNamed('/route/inconnue');
    await tester.pumpAndSettle();

    expect(find.text('Route inconnue'), findsOneWidget);
    expect(find.text('/route/inconnue'), findsOneWidget);
  });

  testWidgets('session scope is available to app widgets', (tester) async {
    await tester.pumpWidget(
      FlowMovaApp(companySearchGateway: companySearchGateway),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(MaterialApp));
    final session = SessionScope.of(context);

    expect(session.isAuthenticated, isFalse);
  });
}

class _FakeCompanySearchGateway implements CompanySearchGateway {
  const _FakeCompanySearchGateway(this.page);

  final CompanySearchPage page;

  @override
  Future<CompanySearchPage> search(CompanySearchQuery query) async => page;
}
