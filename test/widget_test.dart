import 'package:flowmova_frontend/src/app/flow_mova_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FlowMova app starts on the home screen', (tester) async {
    await tester.pumpWidget(const FlowMovaApp());

    expect(find.text('FlowMova'), findsOneWidget);
    expect(
      find.text(
        'Fluidifier la relation entre les entreprises et leurs clients.',
      ),
      findsOneWidget,
    );
    expect(find.text('Parcours client'), findsOneWidget);
    expect(find.text('Espace entreprise'), findsOneWidget);
  });
}
