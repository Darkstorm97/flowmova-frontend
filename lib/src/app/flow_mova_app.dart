import 'package:flutter/material.dart';

import '../core/theme/flow_mova_theme.dart';
import '../features/home/presentation/home_screen.dart';

class FlowMovaApp extends StatelessWidget {
  const FlowMovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlowMova',
      debugShowCheckedModeBanner: false,
      theme: FlowMovaTheme.light,
      home: const HomeScreen(),
    );
  }
}
