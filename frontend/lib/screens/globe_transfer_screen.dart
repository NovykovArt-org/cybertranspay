import 'dart:math' as math;

import 'package:cybertranspay/models/country.dart';
import 'package:cybertranspay/models/globe_transfer.dart';
import 'package:flutter/material.dart';

class GlobeTransferScreen extends StatefulWidget {
  const GlobeTransferScreen({super.key});

  @override
  State<GlobeTransferScreen> createState() => _GlobeTransferScreenState();
}

class _GlobeTransferScreenState extends State<GlobeTransferScreen>
    with SingleTickerProviderStateMixin {
  late GlobeTransferDraft _draft;
  late final AnimationController _progressController;
  GlobeTransferStatus _status = GlobeTransferStatus.idle;

  @override
  void initState() {
    super.initState();
    _draft = GlobeTransferDraft(
      from: supportedCountries[0],
      to: supportedCountries[1],
      amount: 1000,
    );
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _startTransfer() async {
    _progressController
      ..stop()
      ..value = 0;
    setState(() => _status = GlobeTransferStatus.pending);

    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() => _status = GlobeTransferStatus.processing);
    await _progressController.animateTo(
      0.94,
      duration: const Duration(seconds: 5),
      curve: Curves.easeInOutCubic,
    );
    if (!mounted) return;
    setState(() => _status = GlobeTransferStatus.completed);
    await _progressController.animateTo(
      1,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOut,
    );
  }

  Future<void> _pickCountry({required bool isFrom}) async {
    final selected = await showDialog<Country>(
      context: context,
      builder: (context) => _CountryPickerDialog(
        title: isFrom ? 'Откуда отправляем' : 'Куда отправляем',
        selected: isFrom ? _draft.from : _draft.to,
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _status = GlobeTransferStatus.idle;
      _progressController.value = 0;
      _draft = isFrom
          ? _draft.copyWith(from: selected)
          : _draft.copyWith(to: selected);
    });
  }

  Future<void> _editAmount() async {
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => _AmountDialog(amount: _draft.amount),
    );
    if (amount == null || !mounted) return;
    setState(() {
      _status = GlobeTransferStatus.idle;
      _progressController.value = 0;
      _draft = _draft.copyWith(amount: amount);
    });
  }

  void _useCountryFromGlobe(Country country) {
    setState(() {
      _status = GlobeTransferStatus.idle;
      _progressController.value = 0;
      if (country.iso2 == _draft.from.iso2) {
        _draft = _draft.copyWith(to: country);
      } else {
        _draft = _draft.copyWith(from: country);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        children: [
          Text(
            'Глобус переводов',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите страны, запустите перевод и следите за маршрутом.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _TransferDraftPanel(
            draft: _draft,
            onPickFrom: () => _pickCountry(isFrom: true),
            onPickTo: () => _pickCountry(isFrom: false),
            onEditAmount: _editAmount,
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, _) => _GlobeCard(
              draft: _draft,
              countries: supportedCountries,
              progress: _visualProgress,
              status: _status,
              onCountryTap: _useCountryFromGlobe,
            ),
          ),
          const SizedBox(height: 16),
          _ProgressPanel(
            draft: _draft,
            status: _status,
            progress: _visualProgress,
            onStart: _status == GlobeTransferStatus.processing ||
                    _status == GlobeTransferStatus.pending
                ? null
                : _startTransfer,
          ),
        ],
      ),
    );
  }

  double get _visualProgress => switch (_status) {
        GlobeTransferStatus.idle => 0,
        GlobeTransferStatus.pending => 0.08,
        GlobeTransferStatus.processing =>
          _progressController.value.clamp(0.12, 0.94),
        GlobeTransferStatus.completed => 1,
        GlobeTransferStatus.failed => _progressController.value,
      };
}

class _TransferDraftPanel extends StatelessWidget {
  const _TransferDraftPanel({
    required this.draft,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onEditAmount,
  });

  final GlobeTransferDraft draft;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback onEditAmount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _CountryAction(
                    label: 'Откуда',
                    country: draft.from,
                    onTap: onPickFrom,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CountryAction(
                    label: 'Куда',
                    country: draft.to,
                    onTap: onPickTo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onEditAmount,
              icon: const Icon(Icons.payments),
              label: Text(
                '${draft.amount.toStringAsFixed(0)} ${draft.from.assetCode}'
                ' → ${draft.to.assetCode}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountryAction extends StatelessWidget {
  const _CountryAction({
    required this.label,
    required this.country,
    required this.onTap,
  });

  final String label;
  final Country country;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      child: Column(
        children: [
          Text(label),
          const SizedBox(height: 4),
          Text('${country.iso2} · ${country.currency}'),
        ],
      ),
    );
  }
}

class _GlobeCard extends StatelessWidget {
  const _GlobeCard({
    required this.draft,
    required this.countries,
    required this.progress,
    required this.status,
    required this.onCountryTap,
  });

  final GlobeTransferDraft draft;
  final List<Country> countries;
  final double progress;
  final GlobeTransferStatus status;
  final ValueChanged<Country> onCountryTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedOpacity(
            opacity: status == GlobeTransferStatus.completed ? 1 : 0,
            duration: const Duration(milliseconds: 450),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.greenAccent.withOpacity(0.55),
                    blurRadius: 64,
                    spreadRadius: 18,
                  ),
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.35),
                    blurRadius: 92,
                    spreadRadius: 30,
                  ),
                ],
              ),
              child: const SizedBox.expand(),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.indigo.shade300,
                  Colors.blueGrey.shade900,
                ],
                center: const Alignment(-0.35, -0.45),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.22),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: CustomPaint(
              painter: _GlobeRoutePainter(
                from: draft.from,
                to: draft.to,
                progress: progress,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: countries
                        .map(
                          (country) => _CountryMarker(
                            country: country,
                            size: constraints.biggest.shortestSide,
                            selected: country.iso2 == draft.from.iso2 ||
                                country.iso2 == draft.to.iso2,
                            onTap: () => onCountryTap(country),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountryMarker extends StatelessWidget {
  const _CountryMarker({
    required this.country,
    required this.size,
    required this.selected,
    required this.onTap,
  });

  final Country country;
  final double size;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final markerSize = selected ? 44.0 : 34.0;
    return Positioned(
      left: country.globeX * size - markerSize / 2,
      top: country.globeY * size - markerSize / 2,
      child: Tooltip(
        message: country.name,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: markerSize,
            height: markerSize,
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.white70,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? Colors.greenAccent : Colors.indigo,
                width: selected ? 3 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              country.iso2,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ),
      ),
    );
  }
}

class _GlobeRoutePainter extends CustomPainter {
  const _GlobeRoutePainter({
    required this.from,
    required this.to,
    required this.progress,
  });

  final Country from;
  final Country to;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final fromPoint =
        Offset(from.globeX * size.width, from.globeY * size.height);
    final toPoint = Offset(to.globeX * size.width, to.globeY * size.height);
    final control = Offset(
      (fromPoint.dx + toPoint.dx) / 2,
      math.min(fromPoint.dy, toPoint.dy) - size.height * 0.16,
    );
    final path = Path()
      ..moveTo(fromPoint.dx, fromPoint.dy)
      ..quadraticBezierTo(control.dx, control.dy, toPoint.dx, toPoint.dy);

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white24
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    final metric = path.computeMetrics().first;
    final animatedPath = metric.extractPath(0, metric.length * progress);
    canvas.drawPath(
      animatedPath,
      Paint()
        ..color = progress >= 1 ? Colors.greenAccent : Colors.cyanAccent
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 5,
    );
  }

  @override
  bool shouldRepaint(covariant _GlobeRoutePainter oldDelegate) =>
      oldDelegate.from != from ||
      oldDelegate.to != to ||
      oldDelegate.progress != progress;
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({
    required this.draft,
    required this.status,
    required this.progress,
    required this.onStart,
  });

  final GlobeTransferDraft draft;
  final GlobeTransferStatus status;
  final double progress;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${draft.from.name} → ${draft.to.name}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Text('${status.label} · ${(progress * 100).round()}%'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.public),
              label: Text(status == GlobeTransferStatus.completed
                  ? 'Запустить заново'
                  : 'Запустить перевод'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountryPickerDialog extends StatelessWidget {
  const _CountryPickerDialog({
    required this.title,
    required this.selected,
  });

  final String title;
  final Country selected;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text(title),
      children: supportedCountries
          .map(
            (country) => RadioListTile<String>(
              value: country.iso2,
              groupValue: selected.iso2,
              title: Text(country.name),
              subtitle: Text('${country.currency} · ${country.assetCode}'),
              onChanged: (_) => Navigator.of(context).pop(country),
            ),
          )
          .toList(),
    );
  }
}

class _AmountDialog extends StatefulWidget {
  const _AmountDialog({required this.amount});

  final double amount;

  @override
  State<_AmountDialog> createState() => _AmountDialogState();
}

class _AmountDialogState extends State<_AmountDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.amount.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Сумма перевода'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Сумма'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () {
            final amount = double.tryParse(_controller.text.trim());
            if (amount != null && amount > 0) {
              Navigator.of(context).pop(amount);
            }
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
