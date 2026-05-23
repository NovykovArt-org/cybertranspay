import 'package:flutter/material.dart';

void main() {
  runApp(const CyberTransPayApp());
}

class CyberTransPayApp extends StatelessWidget {
  const CyberTransPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CyberTransPay',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CyberTransPay')),
      body: const Center(
        child: Text(
          'Pre-MVP — instant cross-border payments\n(crypto ↔ fiat)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
