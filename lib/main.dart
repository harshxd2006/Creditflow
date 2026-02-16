import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const CreditFlowApp());
}

class CreditFlowApp extends StatelessWidget {
  const CreditFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CreditFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: Colors.tealAccent,
          secondary: Colors.tealAccent,
          surface: const Color(0xFF1D1E33),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
