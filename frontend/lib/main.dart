import 'package:cybertranspay/screens/globe_transfer_screen.dart';
import 'package:cybertranspay/screens/quote_screen.dart';
import 'package:cybertranspay/services/api_client.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(CyberTransPayApp(api: ApiClient()));
}

class CyberTransPayApp extends StatelessWidget {
  const CyberTransPayApp({super.key, required this.api});

  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CyberTransPay',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: HomeShell(api: api),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.api});

  final ApiClient api;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      GlobeTransferScreen(api: widget.api),
      QuoteScreen(api: widget.api),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.public), label: 'Глобус'),
          NavigationDestination(icon: Icon(Icons.route), label: 'Маршруты'),
        ],
      ),
    );
  }
}
