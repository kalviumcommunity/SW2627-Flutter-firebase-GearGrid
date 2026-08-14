import 'package:flutter/material.dart';

import 'screens/landing_page.dart';

void main() {
  runApp(const GearGridApp());
}

class GearGridApp extends StatelessWidget {
  const GearGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GearGrid',
      theme: ThemeData(useMaterial3: true),
      home: const LandingPage(),
    );
  }
}
