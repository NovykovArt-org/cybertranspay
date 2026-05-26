import 'package:cybertranspay/models/route_quote.dart';
import 'package:cybertranspay/services/api_client.dart';
import 'package:flutter/material.dart';

class QuoteScreen extends StatefulWidget {
  const QuoteScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen> {
  final _fromController = TextEditingController(text: 'USDT');
  final _toController = TextEditingController(text: 'EUR');
  final _amountController = TextEditingController(text: '1000');
  String _preference = 'cheapest';
  bool _loading = false;
  String? _executingRouteId;
  String? _error;
  String? _transferError;
  List<RouteQuote> _routes = [];
  QuoteResponse? _lastQuote;
  TransferResponse? _lastTransfer;
  bool? _apiHealthy;

  @override
  void initState() {
    super.initState();
    _checkHealth();
  }

  Future<void> _checkHealth() async {
    try {
      final ok = await widget.api.checkHealth();
      if (mounted) setState(() => _apiHealthy = ok);
    } catch (_) {
      if (mounted) setState(() => _apiHealthy = false);
    }
  }

  Future<void> _fetchQuote() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Введите корректную сумму');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _transferError = null;
      _lastTransfer = null;
    });

    try {
      final response = await widget.api.fetchQuote(
        QuoteRequest(
          fromAsset: _fromController.text.trim().toUpperCase(),
          toAsset: _toController.text.trim().toUpperCase(),
          amount: amount,
          preference: _preference,
        ),
      );
      if (!mounted) return;
      setState(() {
        _routes = response.routes;
        _lastQuote = response;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
        _routes = [];
        _lastQuote = null;
        _lastTransfer = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось связаться с API: $e';
        _loading = false;
        _routes = [];
        _lastQuote = null;
        _lastTransfer = null;
      });
    }
  }

  Future<void> _createTransfer(RouteQuote route) async {
    final quote = _lastQuote;
    if (quote == null) {
      setState(() => _transferError = 'Сначала получите котировку маршрута');
      return;
    }

    setState(() {
      _executingRouteId = route.routeId;
      _transferError = null;
      _lastTransfer = null;
    });

    try {
      final transfer = await widget.api.createTransfer(
        CreateTransferRequest(
          quoteId: quote.quoteId,
          routeId: route.routeId,
        ),
      );
      if (!mounted) return;
      setState(() {
        _lastTransfer = transfer;
        _executingRouteId = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _transferError = e.message;
        _executingRouteId = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _transferError = 'Не удалось выполнить перевод: $e';
        _executingRouteId = null;
      });
    }
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Маршрутизация',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Icon(
                _apiHealthy == true
                    ? Icons.cloud_done
                    : _apiHealthy == false
                        ? Icons.cloud_off
                        : Icons.cloud_queue,
                color: _apiHealthy == true ? Colors.green : Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _fromController,
            decoration: const InputDecoration(labelText: 'От (актив)'),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _toController,
            decoration: const InputDecoration(labelText: 'К (актив)'),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(labelText: 'Сумма'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _preference,
            decoration: const InputDecoration(labelText: 'Приоритет'),
            items: const [
              DropdownMenuItem(value: 'cheapest', child: Text('Дешевле')),
              DropdownMenuItem(value: 'fastest', child: Text('Быстрее')),
              DropdownMenuItem(value: 'compliant', child: Text('Compliance')),
            ],
            onChanged: (v) => setState(() => _preference = v ?? 'cheapest'),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loading ? null : _fetchQuote,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.route),
            label: const Text('Подобрать маршрут'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 20),
          if (_routes.isEmpty && !_loading && _error == null)
            const Text('Выберите пару активов и запросите котировку маршрута.'),
          if (_lastQuote != null) ...[
            Text(
              'Quote: ${_lastQuote!.quoteId} · expires: '
              '${_lastQuote!.expiresAt.toLocal().toIso8601String().substring(0, 16)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Курс: ${_lastQuote!.spotRate.toStringAsFixed(4)} (${_lastQuote!.rateSource})'
              '${_lastQuote!.livePricing ? ' · live' : ''}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
          ],
          if (_transferError != null) ...[
            Text(
              _transferError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 8),
          ],
          if (_lastTransfer != null) ...[
            _TransferReceipt(_lastTransfer!),
            const SizedBox(height: 12),
          ],
          ..._routes.map(
            (route) => _RouteCard(
              route,
              executing: _executingRouteId == route.routeId,
              onCreateTransfer: _executingRouteId == null
                  ? () => _createTransfer(route)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard(
    this.route, {
    required this.executing,
    required this.onCreateTransfer,
  });
  final RouteQuote route;
  final bool executing;
  final VoidCallback? onCreateTransfer;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(route.label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('ID: ${route.routeId}'),
            Text('Rails: ${route.rails.join(' → ')}'),
            const SizedBox(height: 8),
            Text('Комиссия: ${route.feePercent}%'),
            Text('ETA: ${route.etaMinutes} мин'),
            Text('Compliance: ${route.complianceScore}/100'),
            Text(
              'К получению: ${route.estimatedReceive.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onCreateTransfer,
              icon: executing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(executing ? 'Выполняем...' : 'Выполнить перевод'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransferReceipt extends StatelessWidget {
  const _TransferReceipt(this.transfer);

  final TransferResponse transfer;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Перевод создан',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text('ID: ${transfer.transferId}'),
            Text('Статус: ${transfer.status}'),
            Text('Маршрут: ${transfer.routeId}'),
            Text(
              'Сумма: ${transfer.amount.toStringAsFixed(2)} '
              '${transfer.fromAsset} → ${transfer.estimatedReceive.toStringAsFixed(2)} '
              '${transfer.toAsset}',
            ),
          ],
        ),
      ),
    );
  }
}
