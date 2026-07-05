import 'package:flutter/material.dart';

import 'app_router.dart';
import 'app_routes.dart';
import '../core/theme/flow_mova_theme.dart';

class FlowMovaApp extends StatelessWidget {
  const FlowMovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlowMova',
      debugShowCheckedModeBanner: false,
      theme: FlowMovaTheme.light,
      initialRoute: AppRoutes.client,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
