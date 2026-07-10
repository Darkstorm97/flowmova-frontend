import 'package:flowmova_frontend/src/app/flow_mova_app.dart';
import 'package:flowmova_frontend/src/core/session/session_scope.dart';
import 'package:flowmova_frontend/src/features/client/data/company_search_gateway.dart';
import 'package:flowmova_frontend/src/features/client/presentation/client_home_screen.dart';
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
          operationalStatus: 'OPEN',
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

    expect(find.text('Decouvrez autour de vous'), findsOneWidget);
    expect(find.text('Accueil'), findsAtLeastNWidgets(1));
    expect(find.text('Tickets'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Entreprise'), findsOneWidget);
    expect(find.text('Cafe Flow'), findsOneWidget);
    expect(find.text('Ouvert'), findsOneWidget);
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
    expect(find.text('Tickets recents'), findsOneWidget);
    expect(find.text('Voir un ticket avec le code'), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Utilisateur FlowMova'), findsOneWidget);
    expect(find.text('Non connecte'), findsWidgets);

    await tester.tap(find.text('Entreprise'));
    await tester.pumpAndSettle();
    expect(find.text('Mes entreprises'), findsAtLeastNWidgets(1));
    expect(find.text('Connectez-vous'), findsOneWidget);
  });

  testWidgets('company card opens the public company detail route', (
    tester,
  ) async {
    Object? capturedArguments;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClientHomeScreen(searchGateway: companySearchGateway),
        ),
        onGenerateRoute: (settings) {
          capturedArguments = settings.arguments;
          return MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Detail entreprise')),
            settings: settings,
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cafe Flow'));
    await tester.pumpAndSettle();

    expect(find.text('Detail entreprise'), findsOneWidget);
    expect(capturedArguments, 'company-1');
  });

  testWidgets('QR shortcut opens the public location screen', (tester) async {
    await tester.pumpWidget(
      FlowMovaApp(companySearchGateway: companySearchGateway),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Scanner un QR code'));
    await tester.pumpAndSettle();

    expect(find.text('QR code'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.text('Accueil'), findsAtLeastNWidgets(1));
    expect(find.text('Tickets'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Entreprise'), findsOneWidget);
    expect(find.text('Commande sur place'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Code ou lien QR'), findsOneWidget);
  });

  testWidgets('tab navigation clears secondary page back stack', (
    tester,
  ) async {
    await tester.pumpWidget(
      FlowMovaApp(companySearchGateway: companySearchGateway),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Scanner un QR code'));
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsOneWidget);

    await tester.tap(find.text('Tickets'));
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsNothing);

    await tester.tap(find.text('Accueil'));
    await tester.pumpAndSettle();
    expect(find.text('Decouvrez autour de vous'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('public location route accepts web hash matrix parameters', (
    tester,
  ) async {
    await tester.pumpWidget(
      FlowMovaApp(companySearchGateway: companySearchGateway),
    );
    await tester.pumpAndSettle();

    Navigator.of(
      tester.element(find.text('Decouvrez autour de vous')),
    ).pushNamed('/locations/public;preview=true');
    await tester.pumpAndSettle();

    expect(find.text('Commande sur place'), findsOneWidget);
    expect(find.text('Route inconnue'), findsNothing);
  });

  testWidgets('unknown route shows a clean not found page', (tester) async {
    await tester.pumpWidget(
      FlowMovaApp(companySearchGateway: companySearchGateway),
    );
    await tester.pumpAndSettle();

    Navigator.of(
      tester.element(find.text('Decouvrez autour de vous')),
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
