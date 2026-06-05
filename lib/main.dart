import 'package:flutter/material.dart';

import 'screens/login_screen.dart';

void main() {
  runApp(const Academia360App());
}

class Academia360App extends StatelessWidget {
  const Academia360App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Academia360',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}