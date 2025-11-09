import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const BCorpQuestApp());
}

class BCorpQuestApp extends StatelessWidget {
  const BCorpQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Б-Корпус Квест',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}