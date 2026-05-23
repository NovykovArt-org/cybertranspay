/// Runtime configuration via `--dart-define`.
///
/// ```bash
/// flutter run \
///   --dart-define=API_BASE_URL=http://localhost:8080 \
///   --dart-define=API_KEY=your-secret-key
/// ```
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  static const String apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: '',
  );

  static bool get hasApiKey => apiKey.isNotEmpty;
}
