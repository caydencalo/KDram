// lib/main.dart
import 'package:flutter/material.dart';
import 'sign_in_page.dart'; 

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Required before platform channels
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'kDram',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const SignInPage(),
    );
  }
}
