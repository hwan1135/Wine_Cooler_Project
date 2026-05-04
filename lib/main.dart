import 'package:flutter/material.dart';
import 'screens/inventory_screen.dart';

void main() => runApp(const WineApp());

class WineApp extends StatelessWidget {
  const WineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      home: const InventoryScreen(),
    );
  }
}
