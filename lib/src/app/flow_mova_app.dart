import 'package:flutter/material.dart';

import '../features/home/presentation/home_screen.dart';

class FlowMovaApp extends StatelessWidget {
  const FlowMovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlowMova',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0EA5A7)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
