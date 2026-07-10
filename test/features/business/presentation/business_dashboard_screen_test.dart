import 'dart:convert';

import 'package:flowmova_frontend/src/app/app_routes.dart';
import 'package:flowmova_frontend/src/core/session/auth_session_controller.dart';
import 'package:flowmova_frontend/src/core/session/session_scope.dart';
import 'package:flowmova_frontend/src/features/business/data/business_dashboard_gateway.dart';
import 'package:flowmova_frontend/src/features/business/presentation/business_dashboard_screen.dart';
import 'package:flowmova_frontend/src/features/business/presentation/edit_company_screen.dart';
import 'package:flowmova_frontend/src/features/client/data/company_detail_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('business dashboard invites signed out users to authenticate', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        sessionController: AuthSessionController.inMemory(),
        gateway: _FakeBusinessDashboardGateway(),
      ),
    );

    expect(find.text('Connectez-vous'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });

  testWidgets('business dashboard displays real company administration data', (
    tester,
  ) async {
    final sessionController = AuthSessionController.inMemory();
    await sessionController.authenticate(_jwt());

    await tester.pumpWidget(
      _TestApp(
        sessionController: sessionController,
        gateway: _FakeBusinessDashboardGateway(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cafe Flow'), findsOneWidget);
    expect(find.text('Ouverte'), findsOneWidget);
    expect(find.text('Services'), findsWidgets);
    expect(find.text('3'), findsWidgets);
    expect(find.text('2 ouverts'), findsOneWidget);
    expect(find.text('Tickets'), findsOneWidget);
    expect(find.text('Catalogue'), findsWidgets);
    expect(find.text('1 categorie'), findsWidgets);
    expect(find.text('Comptoir'), findsOneWidget);
    expect(find.text('Latte'), findsOneWidget);
  });

  testWidgets('business dashboard opens company edition with current company', (
    tester,
  ) async {
    final sessionController = AuthSessionController.inMemory();
    await sessionController.authenticate(_jwt());

    await tester.pumpWidget(
      _TestApp(
        sessionController: sessionController,
        gateway: _FakeBusinessDashboardGateway(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Modifier entreprise'));
    await tester.pumpAndSettle();

    expect(find.text('Edit company-1'), findsOneWidget);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.sessionController, required this.gateway});

  final AuthSessionController sessionController;
  final BusinessDashboardGateway gateway;

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      controller: sessionController,
      child: MaterialApp(
        home: Scaffold(
          body: BusinessDashboardScreen(
            companyId: 'company-1',
            gateway: gateway,
          ),
        ),
        routes: {
          AppRoutes.login: (_) => const Scaffold(body: Text('Login route')),
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

class _FakeBusinessDashboardGateway implements BusinessDashboardGateway {
  @override
  Future<BusinessDashboardBundle> getDashboard(String companyId) async {
    return BusinessDashboardBundle(
      company: _company(),
      services: BusinessServiceUnitPage(
        items: [
          _service(),
          _service(id: 'service-2', name: 'Salon'),
        ],
        page: 0,
        size: 6,
        totalItems: 3,
        totalPages: 1,
      ),
      catalogCategories: [_category()],
      catalogs: [_catalog()],
    );
  }
}

CompanyDetail _company() {
  return const CompanyDetail(
    id: 'company-1',
    name: 'Cafe Flow',
    description: 'Comptoir rapide pour les tests.',
    imageUrl: null,
    currency: 'CAD',
    businessType: 'RESTAURANT',
    addressLine1: '100 Rue Flow',
    city: 'Montreal',
    region: 'Quebec',
    postalCode: 'H2X 1Y4',
    country: 'CA',
    status: 'ACTIVE',
    operationalStatus: 'OPEN',
  );
}

BusinessServiceUnit _service({
  String id = 'service-1',
  String name = 'Comptoir',
}) {
  return BusinessServiceUnit(
    id: id,
    companyId: 'company-1',
    name: name,
    description: 'Commandes rapides.',
    location: 'Montreal',
    type: 'ORDER',
    status: 'OPEN',
    ticketCreationGuardMode: 'ALWAYS_ALLOWED',
    creationEntryMode: 'PUBLIC_AND_QR',
    defaultLocation: const CompanyServiceUnitLocation(
      id: 'location-1',
      serviceUnitId: 'service-1',
      name: 'Salle',
      type: 'ONSITE',
      defaultLocation: true,
      status: 'ACTIVE',
    ),
  );
}

CompanyCatalogCategory _category() {
  return const CompanyCatalogCategory(
    id: 'category-1',
    companyId: 'company-1',
    name: 'Boissons',
    displayOrder: 1,
    status: 'ACTIVE',
  );
}

CompanyCatalogItem _catalog() {
  return const CompanyCatalogItem(
    id: 'catalog-1',
    name: 'Latte',
    catalogCategoryId: 'category-1',
    priceAmount: 4.5,
    status: 'ACTIVE',
  );
}

String _jwt() {
  final header = base64UrlEncode(
    utf8.encode(jsonEncode({'alg': 'none', 'typ': 'JWT'})),
  );
  final payload = base64UrlEncode(
    utf8.encode(
      jsonEncode({
        'sub': 'user-1',
        'email': 'user@example.com',
        'name': 'User Demo',
        'exp': DateTime.now().add(const Duration(hours: 1)).secondsSinceEpoch,
      }),
    ),
  );
  return '$header.$payload.';
}

extension on DateTime {
  int get secondsSinceEpoch => millisecondsSinceEpoch ~/ 1000;
}
