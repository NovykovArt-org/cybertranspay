import 'package:cybertranspay/config.dart';
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
      const _WelcomeTab(apiBaseUrl: AppConfig.apiBaseUrl),
      const GlobeTransferScreen(),
      QuoteScreen(api: widget.api),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Главная'),
          NavigationDestination(icon: Icon(Icons.public), label: 'Глобус'),
          NavigationDestination(icon: Icon(Icons.route), label: 'Маршрут'),
        ],
      ),
    );
  }
}

class _WelcomeTab extends StatelessWidget {
  const _WelcomeTab({required this.apiBaseUrl});

  final String apiBaseUrl;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'CyberTransPay',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Мгновенные трансграничные платежи\ncrypto ↔ fiat',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text('API: $apiBaseUrl',
                style: Theme.of(context).textTheme.bodySmall),
            if (!AppConfig.hasApiKey)
              Text(
                'API_KEY не задан — нужен, если AUTH_REQUIRED=true',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}
