import 'package:flowmova_frontend/src/app/flow_mova_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FlowMova app starts on the client space', (tester) async {
    await tester.pumpWidget(const FlowMovaApp());

    expect(
      find.text('Trouvez une entreprise et creez votre demande.'),
      findsOneWidget,
    );
    expect(find.text('Accueil'), findsOneWidget);
    expect(find.text('Tickets'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Entreprise'), findsOneWidget);
    expect(find.text('Rechercher une entreprise'), findsOneWidget);
    expect(find.text('Scanner un QR code'), findsOneWidget);
    expect(find.text('Consulter un ticket'), findsNothing);
  });

  testWidgets('main navigation opens tickets profile and business spaces', (
    tester,
  ) async {
    await tester.pumpWidget(const FlowMovaApp());

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
    await tester.pumpWidget(const FlowMovaApp());

    Navigator.of(
      tester.element(
        find.text('Trouvez une entreprise et creez votre demande.'),
      ),
    ).pushNamed('/route/inconnue');
    await tester.pumpAndSettle();

    expect(find.text('Route inconnue'), findsOneWidget);
    expect(find.text('/route/inconnue'), findsOneWidget);
  });
}
