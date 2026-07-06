import 'package:flutter/material.dart';

import '../core/session/auth_session_controller.dart';
import '../core/session/session_scope.dart';
import '../core/theme/flow_mova_theme.dart';
import 'app_router.dart';
import 'app_routes.dart';

class FlowMovaApp extends StatefulWidget {
  const FlowMovaApp({super.key, this.sessionController});

  final AuthSessionController? sessionController;

  @override
  State<FlowMovaApp> createState() => _FlowMovaAppState();
}

class _FlowMovaAppState extends State<FlowMovaApp> {
  late final AuthSessionController _sessionController =
      widget.sessionController ?? AuthSessionController.inMemory();

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
        onGenerateRoute: AppRouter.onGenerateRoute,
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
