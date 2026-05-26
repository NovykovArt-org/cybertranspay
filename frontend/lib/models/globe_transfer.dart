import 'package:flutter/material.dart';

class TransferCountry {
  const TransferCountry({
    required this.name,
    required this.iso2,
    required this.currency,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String iso2;
  final String currency;
  final double latitude;
  final double longitude;

  String get label => '$name ($currency)';
}

class TransferDraft {
  const TransferDraft({
    this.fromCountry,
    this.toCountry,
    this.fromCurrency,
    this.toCurrency,
    this.amount = 1000,
    this.preference = 'cheapest',
  });

  final TransferCountry? fromCountry;
  final TransferCountry? toCountry;
  final String? fromCurrency;
  final String? toCurrency;
  final double amount;
  final String preference;

  bool get hasCountries => fromCountry != null && toCountry != null;
  bool get canRequestQuote =>
      hasCountries &&
      (fromCurrency ?? '').isNotEmpty &&
      (toCurrency ?? '').isNotEmpty &&
      amount > 0;

  TransferDraft copyWith({
    TransferCountry? fromCountry,
    TransferCountry? toCountry,
    String? fromCurrency,
    String? toCurrency,
    double? amount,
    String? preference,
  }) {
    return TransferDraft(
      fromCountry: fromCountry ?? this.fromCountry,
      toCountry: toCountry ?? this.toCountry,
      fromCurrency: fromCurrency ?? this.fromCurrency,
      toCurrency: toCurrency ?? this.toCurrency,
      amount: amount ?? this.amount,
      preference: preference ?? this.preference,
    );
  }

  TransferDraft withFromCountry(TransferCountry country) => copyWith(
        fromCountry: country,
        fromCurrency: fromCurrency ?? country.currency,
      );

  TransferDraft withToCountry(TransferCountry country) => copyWith(
        toCountry: country,
        toCurrency: toCurrency ?? country.currency,
      );
}

class TransferProgress {
  const TransferProgress({
    required this.status,
    required this.percent,
    required this.color,
    required this.label,
    this.failed = false,
    this.completed = false,
  });

  final String status;
  final double percent;
  final Color color;
  final String label;
  final bool failed;
  final bool completed;

  factory TransferProgress.fromStatus(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'pending':
        return const TransferProgress(
          status: 'pending',
          percent: 0.1,
          color: Colors.amber,
          label: 'Ожидает запуска',
        );
      case 'processing':
        return const TransferProgress(
          status: 'processing',
          percent: 0.65,
          color: Colors.amber,
          label: 'В обработке',
        );
      case 'completed':
        return const TransferProgress(
          status: 'completed',
          percent: 1,
          color: Colors.greenAccent,
          label: 'Завершён',
          completed: true,
        );
      case 'failed':
        return const TransferProgress(
          status: 'failed',
          percent: 0.95,
          color: Colors.redAccent,
          label: 'Остановлен',
          failed: true,
        );
      default:
        return const TransferProgress(
          status: 'draft',
          percent: 0,
          color: Colors.amber,
          label: 'Черновик',
        );
    }
  }
}

const supportedTransferCurrencies = [
  'USDT',
  'USDC',
  'USD',
  'EUR',
  'GBP',
  'CHF',
  'CNY',
  'JPY',
  'PLN',
  'TRY',
  'RUB',
  'AED',
];

const transferCountries = [
  TransferCountry(
    name: 'United States',
    iso2: 'US',
    currency: 'USDT',
    latitude: 38.9,
    longitude: -77,
  ),
  TransferCountry(
    name: 'Germany',
    iso2: 'DE',
    currency: 'EUR',
    latitude: 52.5,
    longitude: 13.4,
  ),
  TransferCountry(
    name: 'United Kingdom',
    iso2: 'GB',
    currency: 'GBP',
    latitude: 51.5,
    longitude: -0.1,
  ),
  TransferCountry(
    name: 'Poland',
    iso2: 'PL',
    currency: 'PLN',
    latitude: 52.2,
    longitude: 21,
  ),
  TransferCountry(
    name: 'Switzerland',
    iso2: 'CH',
    currency: 'CHF',
    latitude: 46.9,
    longitude: 7.4,
  ),
  TransferCountry(
    name: 'Turkey',
    iso2: 'TR',
    currency: 'TRY',
    latitude: 39.9,
    longitude: 32.9,
  ),
  TransferCountry(
    name: 'United Arab Emirates',
    iso2: 'AE',
    currency: 'AED',
    latitude: 25.2,
    longitude: 55.3,
  ),
  TransferCountry(
    name: 'China',
    iso2: 'CN',
    currency: 'CNY',
    latitude: 39.9,
    longitude: 116.4,
  ),
  TransferCountry(
    name: 'Japan',
    iso2: 'JP',
    currency: 'JPY',
    latitude: 35.7,
    longitude: 139.7,
  ),
  TransferCountry(
    name: 'Russia',
    iso2: 'RU',
    currency: 'RUB',
    latitude: 55.8,
    longitude: 37.6,
  ),
];
