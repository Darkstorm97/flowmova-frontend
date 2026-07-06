import 'dart:convert';

import 'package:flowmova_frontend/src/app/app_routes.dart';
import 'package:flowmova_frontend/src/core/api/api_exception.dart';
import 'package:flowmova_frontend/src/core/session/auth_session_controller.dart';
import 'package:flowmova_frontend/src/core/session/session_scope.dart';
import 'package:flowmova_frontend/src/features/profile/data/profile_gateway.dart';
import 'package:flowmova_frontend/src/features/profile/presentation/profile_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('profile invites signed out users to authenticate', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        sessionController: AuthSessionController.inMemory(),
        profileGateway: _FakeProfileGateway(),
      ),
    );

    expect(find.text('Vous n etes pas connecte'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Creer un compte'), findsOneWidget);
  });

  testWidgets('profile displays current user information', (tester) async {
    final sessionController = AuthSessionController.inMemory();
    await sessionController.authenticate(_jwt());

    await tester.pumpWidget(
      _TestApp(
        sessionController: sessionController,
        profileGateway: _FakeProfileGateway(
          profile: const UserProfile(
            id: 'user-1',
            email: 'ada@test.dev',
            firstName: 'Ada',
            lastName: 'Lovelace',
            phone: '+1 514 555 0101',
            preferredLanguage: 'fr',
            status: 'ACTIVE',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mes infos profil'), findsOneWidget);
    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('ada@test.dev'), findsOneWidget);
    expect(find.text('+1 514 555 0101'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.text('Se deconnecter'), findsOneWidget);
  });

  testWidgets('profile can sign out authenticated user', (tester) async {
    final sessionController = AuthSessionController.inMemory();
    await sessionController.authenticate(_jwt());

    await tester.pumpWidget(
      _TestApp(
        sessionController: sessionController,
        profileGateway: _FakeProfileGateway(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Se deconnecter'));
    await tester.pumpAndSettle();

    expect(sessionController.isAuthenticated, isFalse);
    expect(find.text('Vous n etes pas connecte'), findsOneWidget);
  });

  testWidgets('profile displays backend errors and retries', (tester) async {
    final sessionController = AuthSessionController.inMemory();
    await sessionController.authenticate(_jwt());
    final profileGateway = _FakeProfileGateway(
      error: const ApiException(
        message: 'Votre session a expire.',
        code: 'UNAUTHORIZED',
      ),
    );

    await tester.pumpWidget(
      _TestApp(
        sessionController: sessionController,
        profileGateway: profileGateway,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profil indisponible'), findsOneWidget);
    expect(find.text('Votre session a expire.'), findsOneWidget);

    profileGateway
      ..error = null
      ..profile = const UserProfile(
        id: 'user-1',
        email: 'ada@test.dev',
        firstName: 'Ada',
        lastName: 'Lovelace',
        status: 'ACTIVE',
      );

    await tester.tap(find.text('Reessayer'));
    await tester.pumpAndSettle();

    expect(find.text('Ada Lovelace'), findsOneWidget);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.sessionController,
    required this.profileGateway,
  });

  final AuthSessionController sessionController;
  final ProfileGateway profileGateway;

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      controller: sessionController,
      child: MaterialApp(
        home: Scaffold(body: ProfileHomeScreen(profileGateway: profileGateway)),
        routes: {
          AppRoutes.login: (_) => const Scaffold(body: Text('Login route')),
          AppRoutes.register: (_) =>
              const Scaffold(body: Text('Register route')),
        },
      ),
    );
  }
}

class _FakeProfileGateway implements ProfileGateway {
  _FakeProfileGateway({this.profile, this.error});

  UserProfile? profile;
  Object? error;

  @override
  Future<UserProfile> getCurrentUserProfile() async {
    final currentError = error;
    if (currentError != null) {
      throw currentError;
    }

    return profile ??
        const UserProfile(
          id: 'user-1',
          email: 'user@test.dev',
          firstName: 'Test',
          lastName: 'User',
          status: 'ACTIVE',
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
