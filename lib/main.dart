import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const PdrAI());
}

class PdrAI extends StatelessWidget {
  const PdrAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PDR AI',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}