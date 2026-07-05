import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app/flow_mova_app.dart';
import 'src/core/session/auth_session_controller.dart';
import 'src/core/session/shared_preferences_token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await SharedPreferences.getInstance();
  final sessionController = AuthSessionController(
    tokenStorage: SharedPreferencesTokenStorage(preferences),
  );
  await sessionController.initialize();

  runApp(FlowMovaApp(sessionController: sessionController));
}
