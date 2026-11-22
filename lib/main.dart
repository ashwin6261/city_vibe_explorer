import 'package:flutter/material.dart';
import 'screens/map_explorer_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CityVibeExplorerApp());
}

class CityVibeExplorerApp extends StatelessWidget {
  const CityVibeExplorerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'City Vibe Explorer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF5722),
          primary: const Color(0xFFFF5722),
          secondary: const Color(0xFF2979FF),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const MapExplorerScreen(),
    );
  }
}

