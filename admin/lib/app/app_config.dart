/// Build-time configuration, supplied via `--dart-define`.
///
/// See `.vscode/launch.json`.
class AppConfig {
  const AppConfig({required this.apiBaseUrl, required this.environment});

  factory AppConfig.fromEnvironment() {
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8080/api/v1',
    );
    const environment = String.fromEnvironment(
      'ENVIRONMENT',
      // Defaults to dev so a plain `flutter run` never silently behaves as production.
      defaultValue: 'dev',
    );
    return const AppConfig(apiBaseUrl: apiBaseUrl, environment: environment);
  }

  final String apiBaseUrl;
  final String environment;

  /// True only for the `prod` launch configuration.
  ///
  /// Compared against an explicit value rather than "not dev", so a typo in ENVIRONMENT
  /// produces a dev-like build rather than an accidentally production-like one.
  bool get isProduction => environment == 'production';
  bool get allowsDevelopmentTools => !isProduction;
}
