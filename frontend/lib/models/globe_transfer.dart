import 'package:cybertranspay/models/country.dart';

class GlobeTransferDraft {
  const GlobeTransferDraft({
    required this.from,
    required this.to,
    required this.amount,
  });

  final Country from;
  final Country to;
  final double amount;

  GlobeTransferDraft copyWith({
    Country? from,
    Country? to,
    double? amount,
  }) =>
      GlobeTransferDraft(
        from: from ?? this.from,
        to: to ?? this.to,
        amount: amount ?? this.amount,
      );
}

enum GlobeTransferStatus {
  idle,
  pending,
  processing,
  completed,
  failed,
}

extension GlobeTransferStatusLabel on GlobeTransferStatus {
  String get label => switch (this) {
        GlobeTransferStatus.idle => 'Готов к запуску',
        GlobeTransferStatus.pending => 'Подготовка',
        GlobeTransferStatus.processing => 'В пути',
        GlobeTransferStatus.completed => 'Доставлено',
        GlobeTransferStatus.failed => 'Ошибка',
      };
}
