// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const BCorpusApp());
}

class BCorpusApp extends StatelessWidget {
  const BCorpusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Б-Корпус Квест',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00D4AA),
          secondary: Color(0xFF2E86AB),
          surface: Color(0xFF151A3A),
          background: Color(0xFF0A0F2D),
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0F2D),
        splashColor: const Color(0xFF00D4AA).withOpacity(0.1),
        highlightColor: Colors.transparent,
      ),
      home: const HomeScreen(),
    );
  }
}