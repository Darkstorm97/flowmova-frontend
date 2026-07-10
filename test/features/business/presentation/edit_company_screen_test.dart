import 'dart:convert';

import 'package:flowmova_frontend/src/app/app_routes.dart';
import 'package:flowmova_frontend/src/core/session/auth_session_controller.dart';
import 'package:flowmova_frontend/src/core/session/session_scope.dart';
import 'package:flowmova_frontend/src/features/business/data/current_user_companies_gateway.dart';
import 'package:flowmova_frontend/src/features/business/presentation/edit_company_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('edit company invites signed out users to authenticate', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        sessionController: AuthSessionController.inMemory(),
        gateway: _FakeCurrentUserCompaniesGateway(),
      ),
    );
    await tester.tap(find.text('Open edit'));
    await tester.pumpAndSettle();

    expect(find.text('Connectez-vous'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });

  testWidgets('edit company pre-fills and submits company update', (
    tester,
  ) async {
    final sessionController = AuthSessionController.inMemory();
    await sessionController.authenticate(_jwt());
    final gateway = _FakeCurrentUserCompaniesGateway();

    await tester.pumpWidget(
      _TestApp(sessionController: sessionController, gateway: gateway),
    );
    await tester.tap(find.text('Open edit'));
    await tester.pumpAndSettle();

    expect(find.text('Modifier l entreprise'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Cafe Flow'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Montreal'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Cafe Flow'),
      'Cafe Flow modifie',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Montreal'),
      'Dakar',
    );
    await tester.ensureVisible(find.text('Enregistrer'));
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(gateway.updatedCompanyId, 'company-1');
    expect(gateway.updatedInput?.name, 'Cafe Flow modifie');
    expect(gateway.updatedInput?.city, 'Dakar');
    expect(gateway.updatedInput?.currency, 'CAD');
    expect(find.text('Updated company-1'), findsOneWidget);
  });
}

class _TestApp extends StatefulWidget {
  const _TestApp({required this.sessionController, required this.gateway});

  final AuthSessionController sessionController;
  final CurrentUserCompaniesGateway gateway;

  @override
  State<_TestApp> createState() => _TestAppState();
}

class _TestAppState extends State<_TestApp> {
  String? _updatedCompanyId;

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      controller: widget.sessionController,
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push<CurrentUserCompany>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          body: EditCompanyScreen(
                            company: _company(),
                            gateway: widget.gateway,
                          ),
                        ),
                      ),
                    );
                    if (result != null && mounted) {
                      setState(() => _updatedCompanyId = result.id);
                    }
                  },
                  child: const Text('Open edit'),
                ),
                if (_updatedCompanyId != null)
                  Text('Updated $_updatedCompanyId'),
              ],
            ),
          ),
        ),
        routes: {
          AppRoutes.login: (_) => const Scaffold(body: Text('Login route')),
        },
      ),
    );
  }
}

class _FakeCurrentUserCompaniesGateway implements CurrentUserCompaniesGateway {
  String? updatedCompanyId;
  CreateCompanyInput? updatedInput;

  @override
  Future<CurrentUserCompanyPage> listCompanies({int page = 0, int size = 10}) {
    throw UnimplementedError();
  }

  @override
  Future<CurrentUserCompany> createCompany(CreateCompanyInput input) {
    throw UnimplementedError();
  }

  @override
  Future<CurrentUserCompany> updateCompany(
    String companyId,
    CreateCompanyInput input,
  ) async {
    updatedCompanyId = companyId;
    updatedInput = input;
    return _company(
      name: input.name,
      city: input.city,
      currency: input.currency,
      operationalStatus: input.operationalStatus,
    );
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
  String name = 'Cafe Flow',
  String? city = 'Montreal',
  String currency = 'CAD',
  String operationalStatus = 'OPEN',
}) {
  return CurrentUserCompany(
    id: 'company-1',
    name: name,
    description: 'Comptoir rapide pour les tests.',
    imageUrl: null,
    currency: currency,
    businessType: 'RESTAURANT',
    addressLine1: '100 Rue Flow',
    city: city,
    region: 'Quebec',
    postalCode: 'H2X 1Y4',
    country: 'CA',
    status: 'ACTIVE',
    operationalStatus: operationalStatus,
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
