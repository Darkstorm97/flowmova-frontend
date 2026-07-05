import 'package:flowmova_frontend/src/app/flow_mova_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FlowMova app starts on the client space', (tester) async {
    await tester.pumpWidget(const FlowMovaApp());

    expect(
      find.text('Trouvez une entreprise et suivez vos demandes.'),
      findsOneWidget,
    );
    expect(find.text('Client'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Entreprise'), findsOneWidget);
    expect(find.text('Rechercher une entreprise'), findsOneWidget);
  });

  testWidgets('main navigation opens profile and business spaces', (
    tester,
  ) async {
    await tester.pumpWidget(const FlowMovaApp());

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
        find.text('Trouvez une entreprise et suivez vos demandes.'),
      ),
    ).pushNamed('/route/inconnue');
    await tester.pumpAndSettle();

    expect(find.text('Route inconnue'), findsOneWidget);
    expect(find.text('/route/inconnue'), findsOneWidget);
  });
}
