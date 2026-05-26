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
  bool _refreshingTransfer = false;
  String? _error;
  String? _transferError;
  String? _transferStatusMessage;
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
      _transferStatusMessage = null;
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
      _transferStatusMessage = null;
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

  Future<void> _refreshTransferStatus() async {
    final transfer = _lastTransfer;
    if (transfer == null) return;

    setState(() {
      _refreshingTransfer = true;
      _transferError = null;
      _transferStatusMessage = null;
    });

    try {
      final refreshed = await widget.api.getTransfer(transfer.transferId);
      if (!mounted) return;
      setState(() {
        _lastTransfer = refreshed;
        _refreshingTransfer = false;
        _transferStatusMessage = 'Статус обновлён';
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _transferError = e.message;
        _refreshingTransfer = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _transferError = 'Не удалось обновить статус: $e';
        _refreshingTransfer = false;
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
          _QuoteHeader(apiHealthy: _apiHealthy),
          const SizedBox(height: 16),
          _QuoteForm(
            fromController: _fromController,
            toController: _toController,
            amountController: _amountController,
            preference: _preference,
            loading: _loading,
            error: _error,
            onPreferenceChanged: (value) => setState(() => _preference = value),
            onSubmit: _fetchQuote,
          ),
          const SizedBox(height: 20),
          if (_routes.isEmpty && !_loading && _error == null)
            const Text('Выберите пару активов и запросите котировку маршрута.'),
          if (_lastQuote != null) _QuoteSummary(_lastQuote!),
          if (_transferError != null) ...[
            Text(
              _transferError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 8),
          ],
          if (_lastTransfer != null) ...[
            _TransferReceipt(
              _lastTransfer!,
              refreshing: _refreshingTransfer,
              statusMessage: _transferStatusMessage,
              onRefresh: _refreshingTransfer ? null : _refreshTransferStatus,
            ),
            const SizedBox(height: 12),
          ],
          ..._routes.map(
            (route) => _RouteCard(
              route,
              executing: _executingRouteId == route.routeId,
              transferCreated: _lastTransfer != null,
              onCreateTransfer:
                  _executingRouteId == null && _lastTransfer == null
                      ? () => _createTransfer(route)
                      : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteHeader extends StatelessWidget {
  const _QuoteHeader({required this.apiHealthy});

  final bool? apiHealthy;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Маршрутизация',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        Icon(
          apiHealthy == true
              ? Icons.cloud_done
              : apiHealthy == false
                  ? Icons.cloud_off
                  : Icons.cloud_queue,
          color: apiHealthy == true ? Colors.green : Colors.orange,
        ),
      ],
    );
  }
}

class _QuoteForm extends StatelessWidget {
  const _QuoteForm({
    required this.fromController,
    required this.toController,
    required this.amountController,
    required this.preference,
    required this.loading,
    required this.error,
    required this.onPreferenceChanged,
    required this.onSubmit,
  });

  final TextEditingController fromController;
  final TextEditingController toController;
  final TextEditingController amountController;
  final String preference;
  final bool loading;
  final String? error;
  final ValueChanged<String> onPreferenceChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: fromController,
          decoration: const InputDecoration(labelText: 'От (актив)'),
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: toController,
          decoration: const InputDecoration(labelText: 'К (актив)'),
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: amountController,
          decoration: const InputDecoration(labelText: 'Сумма'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: preference,
          decoration: const InputDecoration(labelText: 'Приоритет'),
          items: const [
            DropdownMenuItem(value: 'cheapest', child: Text('Дешевле')),
            DropdownMenuItem(value: 'fastest', child: Text('Быстрее')),
            DropdownMenuItem(value: 'compliant', child: Text('Compliance')),
          ],
          onChanged: (value) => onPreferenceChanged(value ?? 'cheapest'),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: loading ? null : onSubmit,
          icon: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.route),
          label: const Text('Подобрать маршрут'),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ],
    );
  }
}

class _QuoteSummary extends StatelessWidget {
  const _QuoteSummary(this.quote);

  final QuoteResponse quote;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quote: ${quote.quoteId} · expires: '
          '${quote.expiresAt.toLocal().toIso8601String().substring(0, 16)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Курс: ${quote.spotRate.toStringAsFixed(4)} (${quote.rateSource})'
          '${quote.livePricing ? ' · live' : ''}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard(
    this.route, {
    required this.executing,
    required this.transferCreated,
    required this.onCreateTransfer,
  });
  final RouteQuote route;
  final bool executing;
  final bool transferCreated;
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
              icon: transferCreated
                  ? const Icon(Icons.check_circle)
                  : executing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
              label: Text(
                transferCreated
                    ? 'Перевод уже создан'
                    : executing
                        ? 'Выполняем...'
                        : 'Выполнить перевод',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransferReceipt extends StatelessWidget {
  const _TransferReceipt(
    this.transfer, {
    required this.refreshing,
    required this.statusMessage,
    required this.onRefresh,
  });

  final TransferResponse transfer;
  final bool refreshing;
  final String? statusMessage;
  final VoidCallback? onRefresh;

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
            _StatusBadge(status: transfer.status),
            Text('Маршрут: ${transfer.routeId}'),
            Text(
              'Сумма: ${transfer.amount.toStringAsFixed(2)} '
              '${transfer.fromAsset} → ${transfer.estimatedReceive.toStringAsFixed(2)} '
              '${transfer.toAsset}',
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: refreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(refreshing ? 'Обновляем...' : 'Обновить статус'),
            ),
            if (statusMessage != null) ...[
              const SizedBox(height: 6),
              Text(statusMessage!),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = switch (status) {
      'completed' => Colors.green,
      'processing' => Colors.blue,
      'pending' => Colors.orange,
      'failed' => colorScheme.error,
      _ => colorScheme.outline,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            'Статус: $status',
            style:
                Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
          ),
        ),
      ),
    );
  }
}
