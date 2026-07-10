import 'dart:convert';

import 'package:flowmova_frontend/src/app/app_routes.dart';
import 'package:flowmova_frontend/src/core/session/auth_session_controller.dart';
import 'package:flowmova_frontend/src/core/session/session_scope.dart';
import 'package:flowmova_frontend/src/features/business/data/current_user_companies_gateway.dart';
import 'package:flowmova_frontend/src/features/business/presentation/create_company_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('create company invites signed out users to authenticate', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        sessionController: AuthSessionController.inMemory(),
        gateway: _FakeCurrentUserCompaniesGateway(),
      ),
    );

    expect(find.text('Connectez-vous'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });

  testWidgets('create company validates required name', (tester) async {
    final sessionController = AuthSessionController.inMemory();
    await sessionController.authenticate(_jwt());

    await tester.pumpWidget(
      _TestApp(
        sessionController: sessionController,
        gateway: _FakeCurrentUserCompaniesGateway(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Creer'));
    await tester.tap(find.text('Creer'));
    await tester.pumpAndSettle();

    expect(find.text('Le nom est requis.'), findsOneWidget);
  });

  testWidgets('create company submits payload and opens dashboard', (
    tester,
  ) async {
    final sessionController = AuthSessionController.inMemory();
    await sessionController.authenticate(_jwt());
    final gateway = _FakeCurrentUserCompaniesGateway();

    await tester.pumpWidget(
      _TestApp(sessionController: sessionController, gateway: gateway),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Nom'), 'Cafe');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Description'),
      'Cafe de test',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ville'),
      'Laval',
    );
    await tester.ensureVisible(find.text('Creer'));
    await tester.tap(find.text('Creer'));
    await tester.pumpAndSettle();

    expect(gateway.createdInput?.name, 'Cafe');
    expect(gateway.createdInput?.description, 'Cafe de test');
    expect(gateway.createdInput?.currency, 'CAD');
    expect(gateway.createdInput?.businessType, 'RESTAURANT');
    expect(gateway.createdInput?.city, 'Laval');
    expect(find.text('Dashboard company-created'), findsOneWidget);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.sessionController, required this.gateway});

  final AuthSessionController sessionController;
  final CurrentUserCompaniesGateway gateway;

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      controller: sessionController,
      child: MaterialApp(
        home: Scaffold(body: CreateCompanyScreen(gateway: gateway)),
        routes: {
          AppRoutes.login: (_) => const Scaffold(body: Text('Login route')),
          AppRoutes.businessDashboard: (context) {
            final companyId = ModalRoute.of(context)!.settings.arguments;
            return Scaffold(body: Text('Dashboard $companyId'));
          },
        },
      ),
    );
  }
}

class _FakeCurrentUserCompaniesGateway implements CurrentUserCompaniesGateway {
  CreateCompanyInput? createdInput;

  @override
  Future<CurrentUserCompanyPage> listCompanies({int page = 0, int size = 10}) {
    throw UnimplementedError();
  }

  @override
  Future<CurrentUserCompany> createCompany(CreateCompanyInput input) async {
    createdInput = input;
    return CurrentUserCompany(
      id: 'company-created',
      name: input.name,
      description: input.description,
      imageUrl: input.imageUrl,
      currency: input.currency,
      businessType: input.businessType,
      city: input.city,
      region: input.region,
      country: input.country,
      status: 'ACTIVE',
      operationalStatus: input.operationalStatus,
      role: 'ADMIN',
      createdAt: DateTime.utc(2026, 7, 9, 12),
      updatedAt: DateTime.utc(2026, 7, 9, 12),
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
