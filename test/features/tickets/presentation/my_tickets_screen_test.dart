import 'dart:convert';

import 'package:flowmova_frontend/src/app/app_routes.dart';
import 'package:flowmova_frontend/src/core/session/auth_session_controller.dart';
import 'package:flowmova_frontend/src/core/session/session_scope.dart';
import 'package:flowmova_frontend/src/features/tickets/data/current_user_ticket_gateway.dart';
import 'package:flowmova_frontend/src/features/tickets/presentation/my_tickets_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('my tickets invites signed out users to authenticate', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        sessionController: AuthSessionController.inMemory(),
        gateway: _FakeCurrentUserTicketGateway(),
      ),
    );

    expect(find.text('Connectez-vous'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Creer un compte'), findsOneWidget);
  });

  testWidgets('my tickets displays current user backend tickets', (
    tester,
  ) async {
    final sessionController = AuthSessionController.inMemory();
    await sessionController.authenticate(_jwt());

    await tester.pumpWidget(
      _TestApp(
        sessionController: sessionController,
        gateway: _FakeCurrentUserTicketGateway(
          tickets: [_ticket(status: 'RECEIVED')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mes tickets'), findsOneWidget);
    expect(find.text('Cafe Flow'), findsWidgets);
    expect(find.text('Comptoir principal - FM-0001'), findsOneWidget);
    expect(find.text('Recu'), findsOneWidget);
    expect(find.text('12.50 CAD'), findsOneWidget);
  });

  testWidgets('my tickets opens detail and confirms treatment', (tester) async {
    final sessionController = AuthSessionController.inMemory();
    await sessionController.authenticate(_jwt());
    final gateway = _FakeCurrentUserTicketGateway(
      tickets: [_ticket(status: 'TREATED')],
    );

    await tester.pumpWidget(
      _TestApp(sessionController: sessionController, gateway: gateway),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cafe Flow').first);
    await tester.pumpAndSettle();

    expect(find.text('Cafe Flow'), findsWidgets);
    expect(find.text('Comptoir principal'), findsWidgets);
    expect(find.text('Table terrasse'), findsNothing);
    expect(find.text('Latte glace'), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Confirmer le traitement'), findsOneWidget);

    await tester.ensureVisible(find.text('Confirmer le traitement'));
    await tester.tap(find.text('Confirmer le traitement'));
    await tester.pumpAndSettle();

    expect(find.text('Confirmer le traitement ?'), findsOneWidget);

    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();

    expect(gateway.confirmedTicketId, 'ticket-1');
    expect(find.text('Confirme'), findsOneWidget);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.sessionController, required this.gateway});

  final AuthSessionController sessionController;
  final CurrentUserTicketGateway gateway;

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      controller: sessionController,
      child: MaterialApp(
        home: Scaffold(body: MyTicketsScreen(gateway: gateway)),
        routes: {
          AppRoutes.login: (_) => const Scaffold(body: Text('Login route')),
          AppRoutes.register: (_) =>
              const Scaffold(body: Text('Register route')),
          AppRoutes.myTicketDetail: (context) {
            final arguments =
                ModalRoute.of(context)!.settings.arguments
                    as MyTicketDetailArguments;
            return Scaffold(
              body: MyTicketDetailScreen(
                ticket: arguments.ticket,
                gateway: arguments.gateway,
              ),
            );
          },
        },
      ),
    );
  }
}

class _FakeCurrentUserTicketGateway implements CurrentUserTicketGateway {
  _FakeCurrentUserTicketGateway({List<CurrentUserTicket>? tickets})
    : tickets = tickets ?? const [];

  List<CurrentUserTicket> tickets;
  String? cancelledTicketId;
  String? confirmedTicketId;

  @override
  Future<CurrentUserTicketPage> listTickets({
    int page = 0,
    int size = 20,
    String? status,
    String? ticketNumber,
  }) async {
    return CurrentUserTicketPage(
      items: tickets,
      page: page,
      size: size,
      totalItems: tickets.length,
      totalPages: tickets.isEmpty ? 0 : 1,
    );
  }

  @override
  Future<CurrentUserTicket> cancelTicket(String ticketId) async {
    cancelledTicketId = ticketId;
    final updatedTicket = tickets
        .firstWhere((ticket) => ticket.id == ticketId)
        .copyWith(status: 'CANCELLED');
    tickets = [updatedTicket];
    return updatedTicket;
  }

  @override
  Future<CurrentUserTicket> confirmTicketTreatment(String ticketId) async {
    confirmedTicketId = ticketId;
    final updatedTicket = tickets
        .firstWhere((ticket) => ticket.id == ticketId)
        .copyWith(status: 'CUSTOMER_CONFIRMED');
    tickets = [updatedTicket];
    return updatedTicket;
  }
}

CurrentUserTicket _ticket({required String status}) {
  return CurrentUserTicket(
    id: 'ticket-1',
    ticketNumber: 'FM-0001',
    userId: 'user-1',
    customerPhone: '+15145550000',
    companyId: 'company-1',
    companyName: 'Cafe Flow',
    serviceUnitId: 'service-unit-1',
    serviceUnitName: 'Comptoir principal',
    locationId: 'location-1',
    locationName: 'Table terrasse',
    locationDefault: true,
    status: status,
    currency: 'CAD',
    totalAmount: 12.5,
    lines: const [
      CurrentUserTicketLine(
        id: 'line-1',
        itemId: 'item-1',
        itemName: 'Latte glace',
        quantity: 2,
        unitPriceAmount: 6.25,
        lineTotalAmount: 12.5,
      ),
    ],
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
