import 'package:flutter/material.dart';

import '../core/session/auth_session_controller.dart';
import '../core/session/session_scope.dart';
import '../core/theme/flow_mova_theme.dart';
import '../features/client/data/company_search_gateway.dart';
import '../features/tickets/data/recent_ticket_storage.dart';
import 'app_router.dart';
import 'app_routes.dart';

class FlowMovaApp extends StatefulWidget {
  const FlowMovaApp({
    super.key,
    this.sessionController,
    this.companySearchGateway,
    this.recentTicketStorage,
  });

  final AuthSessionController? sessionController;
  final CompanySearchGateway? companySearchGateway;
  final RecentTicketStorage? recentTicketStorage;

  @override
  State<FlowMovaApp> createState() => _FlowMovaAppState();
}

class _FlowMovaAppState extends State<FlowMovaApp> {
  late final AuthSessionController _sessionController =
      widget.sessionController ?? AuthSessionController.inMemory();
  late final RecentTicketStorage _recentTicketStorage =
      widget.recentTicketStorage ?? InMemoryRecentTicketStorage();

  @override
  void initState() {
    super.initState();
    _sessionController.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      controller: _sessionController,
      child: MaterialApp(
        title: 'FlowMova',
        debugShowCheckedModeBanner: false,
        theme: FlowMovaTheme.light,
        initialRoute: AppRoutes.client,
        onGenerateRoute: (settings) => AppRouter.onGenerateRoute(
          settings,
          companySearchGateway: widget.companySearchGateway,
          recentTicketStorage: _recentTicketStorage,
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (widget.sessionController == null) {
      _sessionController.dispose();
    }
    super.dispose();
  }
}
