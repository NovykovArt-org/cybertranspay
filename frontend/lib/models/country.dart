class Country {
  const Country({
    required this.iso2,
    required this.name,
    required this.currency,
    required this.assetCode,
    required this.globeX,
    required this.globeY,
  });

  final String iso2;
  final String name;
  final String currency;
  final String assetCode;

  /// Normalized pseudo-globe coordinates in the 0..1 range.
  final double globeX;
  final double globeY;
}

const supportedCountries = [
  Country(
    iso2: 'US',
    name: 'United States',
    currency: 'USD',
    assetCode: 'USDT',
    globeX: 0.24,
    globeY: 0.42,
  ),
  Country(
    iso2: 'DE',
    name: 'Germany',
    currency: 'EUR',
    assetCode: 'EUR',
    globeX: 0.53,
    globeY: 0.35,
  ),
  Country(
    iso2: 'AE',
    name: 'United Arab Emirates',
    currency: 'AED',
    assetCode: 'USDC',
    globeX: 0.62,
    globeY: 0.52,
  ),
  Country(
    iso2: 'TR',
    name: 'Turkey',
    currency: 'TRY',
    assetCode: 'USDT',
    globeX: 0.57,
    globeY: 0.46,
  ),
  Country(
    iso2: 'JP',
    name: 'Japan',
    currency: 'JPY',
    assetCode: 'JPY',
    globeX: 0.78,
    globeY: 0.42,
  ),
  Country(
    iso2: 'BR',
    name: 'Brazil',
    currency: 'BRL',
    assetCode: 'USD',
    globeX: 0.39,
    globeY: 0.72,
  ),
];
