import 'dart:convert';

import 'package:flowmova_frontend/src/app/app_routes.dart';
import 'package:flowmova_frontend/src/core/session/auth_session_controller.dart';
import 'package:flowmova_frontend/src/core/session/session_scope.dart';
import 'package:flowmova_frontend/src/features/auth/data/auth_gateway.dart';
import 'package:flowmova_frontend/src/features/auth/presentation/login_screen.dart';
import 'package:flowmova_frontend/src/features/auth/presentation/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('login authenticates and redirects to profile', (tester) async {
    final sessionController = AuthSessionController.inMemory();
    final authGateway = _FakeAuthGateway(
      loginResult: LoginUserResult(
        accessToken: _jwt(
          expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
        tokenType: 'Bearer',
        expiresIn: 3600,
      ),
    );

    await tester.pumpWidget(
      _TestApp(
        sessionController: sessionController,
        home: LoginScreen(authGateway: authGateway),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'user@test.dev');
    await tester.enterText(find.byType(TextFormField).at(1), 'Password123');
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(sessionController.isAuthenticated, isTrue);
    expect(find.text('Profil route'), findsOneWidget);
    expect(authGateway.loginCommand?.email, 'user@test.dev');
  });

  testWidgets(
    'register validates fields and redirects to login after success',
    (tester) async {
      final authGateway = _FakeAuthGateway(
        registerResult: const RegisterUserResult(
          id: 'user-1',
          email: 'user@test.dev',
          firstName: 'Ada',
          lastName: 'Lovelace',
          status: 'ACTIVE',
        ),
      );

      await tester.pumpWidget(
        _TestApp(
          sessionController: AuthSessionController.inMemory(),
          home: RegisterScreen(authGateway: authGateway),
        ),
      );

      await tester.ensureVisible(find.text('Creer mon compte'));
      await tester.tap(find.text('Creer mon compte'));
      await tester.pump();
      expect(find.text('Champ requis'), findsNWidgets(2));
      expect(find.text('Email requis'), findsOneWidget);
      expect(find.text('Mot de passe requis'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'Ada');
      await tester.enterText(find.byType(TextFormField).at(1), 'Lovelace');
      await tester.enterText(find.byType(TextFormField).at(2), 'user@test.dev');
      await tester.enterText(find.byType(TextFormField).at(3), 'Password123');
      await tester.ensureVisible(find.text('Creer mon compte'));
      await tester.tap(find.text('Creer mon compte'));
      await tester.pumpAndSettle();

      expect(find.text('Login route'), findsOneWidget);
      expect(authGateway.registerCommand?.email, 'user@test.dev');
    },
  );
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.sessionController, required this.home});

  final AuthSessionController sessionController;
  final Widget home;

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      controller: sessionController,
      child: MaterialApp(
        home: home,
        routes: {
          AppRoutes.profile: (_) => const Scaffold(body: Text('Profil route')),
          AppRoutes.login: (_) => const Scaffold(body: Text('Login route')),
          AppRoutes.register: (_) =>
              const Scaffold(body: Text('Register route')),
        },
      ),
    );
  }
}

class _FakeAuthGateway implements AuthGateway {
  _FakeAuthGateway({this.registerResult, this.loginResult});

  final RegisterUserResult? registerResult;
  final LoginUserResult? loginResult;
  RegisterUserCommand? registerCommand;
  LoginUserCommand? loginCommand;

  @override
  Future<RegisterUserResult> register(RegisterUserCommand command) async {
    registerCommand = command;
    return registerResult ??
        const RegisterUserResult(
          id: 'user-1',
          email: 'user@test.dev',
          firstName: 'Test',
          lastName: 'User',
          status: 'ACTIVE',
        );
  }

  @override
  Future<LoginUserResult> login(LoginUserCommand command) async {
    loginCommand = command;
    return loginResult ??
        const LoginUserResult(
          accessToken: 'opaque-token',
          tokenType: 'Bearer',
          expiresIn: 3600,
        );
  }
}

String _jwt({required DateTime expiresAt}) {
  final header = _encode({'alg': 'none', 'typ': 'JWT'});
  final payload = _encode({'exp': expiresAt.millisecondsSinceEpoch ~/ 1000});
  return '$header.$payload.signature';
}

String _encode(Map<String, dynamic> json) {
  return base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
}
