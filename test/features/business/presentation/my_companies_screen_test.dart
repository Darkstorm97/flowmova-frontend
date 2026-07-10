import 'dart:convert';

import 'package:flowmova_frontend/src/app/app_routes.dart';
import 'package:flowmova_frontend/src/core/session/auth_session_controller.dart';
import 'package:flowmova_frontend/src/core/session/session_scope.dart';
import 'package:flowmova_frontend/src/features/business/data/current_user_companies_gateway.dart';
import 'package:flowmova_frontend/src/features/business/presentation/edit_company_screen.dart';
import 'package:flowmova_frontend/src/features/business/presentation/my_companies_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('my companies invites signed out users to authenticate', (
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
    expect(find.text('Creer un compte'), findsOneWidget);
  });

  testWidgets('my companies displays current user backend companies', (
    tester,
  ) async {
    final sessionController = AuthSessionController.inMemory();
    await sessionController.authenticate(_jwt());

    await tester.pumpWidget(
      _TestApp(
        sessionController: sessionController,
        gateway: _FakeCurrentUserCompaniesGateway(
          companies: [_company(name: 'Cafe Flow')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mes entreprises'), findsOneWidget);
    expect(find.text('1 entreprise'), findsOneWidget);
    expect(find.text('Cafe Flow'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Restauration'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Ouverte'), findsOneWidget);
    expect(find.text('Montreal, Quebec, CA'), findsOneWidget);
  });

  testWidgets('my companies filters current page locally', (tester) async {
    final sessionController = AuthSessionController.inMemory();
    await sessionController.authenticate(_jwt());

    await tester.pumpWidget(
      _TestApp(
        sessionController: sessionController,
        gateway: _FakeCurrentUserCompaniesGateway(
          companies: [
            _company(name: 'Cafe Flow'),
            _company(id: 'company-2', name: 'Salon Mova', city: 'Laval'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 entreprises'), findsOneWidget);
    expect(find.text('Cafe Flow'), findsOneWidget);
    expect(find.text('Salon Mova'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'salon');
    await tester.pumpAndSettle();

    expect(find.text('1 resultat sur 2 entreprises'), findsOneWidget);
    expect(find.text('Salon Mova'), findsOneWidget);
    expect(find.text('Cafe Flow'), findsNothing);

    await tester.enterText(find.byType(TextField), 'introuvable');
    await tester.pumpAndSettle();

    expect(find.text('Aucune entreprise trouvee'), findsOneWidget);
    expect(
      find.text('Aucune entreprise ne correspond a "introuvable".'),
      findsOneWidget,
    );
  });

  testWidgets('my companies opens selected company dashboard', (tester) async {
    final sessionController = AuthSessionController.inMemory();
    await sessionController.authenticate(_jwt());

    await tester.pumpWidget(
      _TestApp(
        sessionController: sessionController,
        gateway: _FakeCurrentUserCompaniesGateway(
          companies: [_company(name: 'Cafe Flow')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cafe Flow'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard company-1'), findsOneWidget);
  });

  testWidgets('my companies opens selected company edition', (tester) async {
    final sessionController = AuthSessionController.inMemory();
    await sessionController.authenticate(_jwt());

    await tester.pumpWidget(
      _TestApp(
        sessionController: sessionController,
        gateway: _FakeCurrentUserCompaniesGateway(
          companies: [_company(name: 'Cafe Flow')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();

    expect(find.text('Edit company-1'), findsOneWidget);
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
        home: Scaffold(body: MyCompaniesScreen(gateway: gateway)),
        routes: {
          AppRoutes.login: (_) => const Scaffold(body: Text('Login route')),
          AppRoutes.register: (_) =>
              const Scaffold(body: Text('Register route')),
          AppRoutes.businessDashboard: (context) {
            final companyId = ModalRoute.of(context)!.settings.arguments;
            return Scaffold(body: Text('Dashboard $companyId'));
          },
          AppRoutes.editCompany: (context) {
            final arguments = ModalRoute.of(context)!.settings.arguments;
            final companyId = arguments is EditCompanyArguments
                ? arguments.company.id
                : 'missing';
            return Scaffold(body: Text('Edit $companyId'));
          },
        },
      ),
    );
  }
}

class _FakeCurrentUserCompaniesGateway implements CurrentUserCompaniesGateway {
  const _FakeCurrentUserCompaniesGateway({this.companies = const []});

  final List<CurrentUserCompany> companies;

  @override
  Future<CurrentUserCompanyPage> listCompanies({
    int page = 0,
    int size = 10,
  }) async {
    return CurrentUserCompanyPage(
      items: companies,
      page: page,
      size: size,
      totalItems: companies.length,
      totalPages: companies.isEmpty ? 0 : 1,
    );
  }

  @override
  Future<CurrentUserCompany> createCompany(CreateCompanyInput input) {
    throw UnimplementedError();
  }

  @override
  Future<CurrentUserCompany> updateCompany(
    String companyId,
    CreateCompanyInput input,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<CurrentUserCompany> uploadCompanyImage(
    String companyId,
    CompanyImageUpload image,
  ) {
    throw UnimplementedError();
  }
}

CurrentUserCompany _company({
  String id = 'company-1',
  required String name,
  String city = 'Montreal',
}) {
  return CurrentUserCompany(
    id: id,
    name: name,
    description: 'Comptoir rapide pour les tests.',
    imageUrl: null,
    currency: 'CAD',
    businessType: 'RESTAURANT',
    city: city,
    region: 'Quebec',
    country: 'CA',
    status: 'ACTIVE',
    operationalStatus: 'OPEN',
    role: 'ADMIN',
    createdAt: DateTime.utc(2026, 7, 7, 12),
    updatedAt: DateTime.utc(2026, 7, 7, 12, 5),
  );
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
