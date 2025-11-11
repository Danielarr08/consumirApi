import 'package:flutter/material.dart';
import 'package:api/features/ui/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4E7CF6),
      brightness: Brightness.light,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Clima',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        appBarTheme: const AppBarTheme(foregroundColor: Colors.white),
      ),
      home: const HomePage(),
    );
  }
}
