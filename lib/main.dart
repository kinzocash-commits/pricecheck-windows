import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const PriceCheckerApp());
}

class PriceCheckerApp extends StatelessWidget {
  const PriceCheckerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Price Checker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
