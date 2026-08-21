import 'dart:io' show Platform;

/// Build-time configuration, supplied via `--dart-define`.
///
/// See `.vscode/launch.json` for the standard combinations, and
/// docs/06-development/LOCAL_SETUP.md for how to point at a local backend.
///
/// Nothing here is a secret. Client-side configuration is visible to anyone holding the
/// binary, so credentials and provider keys live server-side in tenant configuration
/// (ADR-0005, docs/02-system-design/SECURITY_ARCHITECTURE.md).
class AppConfig {
  const AppConfig({required this.apiBaseUrl, required this.environment});

  factory AppConfig.fromEnvironment() {
    const configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
    const environment = String.fromEnvironment(
      'ENVIRONMENT',
      // Defaults to dev so a plain `flutter run` never silently behaves as production.
      defaultValue: 'dev',
    );
    return AppConfig(
      apiBaseUrl:
          configuredBaseUrl.isNotEmpty ? configuredBaseUrl : _defaultLocalBaseUrl(),
      environment: environment,
    );
  }

  /// Where a plain `flutter run` looks for a backend, when no `API_BASE_URL` was supplied.
  ///
  /// **The Android value is not a typo.** Inside an emulator, `localhost` is the emulator
  /// itself, so a backend running perfectly well on the developer's machine is simply not
  /// there — and the app reports it the same way it reports a real outage, which sends people
  /// looking at the server. `10.0.2.2` is the loopback alias the emulator maps to its host.
  ///
  /// A physical Android device reaches neither: use `adb reverse tcp:8080 tcp:8080` and pass
  /// `--dart-define=API_BASE_URL=http://localhost:8080/api/v1`, or pass the machine's LAN
  /// address. Both are explicit, which is why they are left to the flag rather than guessed
  /// at here.
  static String _defaultLocalBaseUrl() {
    if (Platform.isAndroid) return 'http://10.0.2.2:8080/api/v1';
    // iOS simulator, macOS, and desktop share the host's network namespace.
    return 'http://localhost:8080/api/v1';
  }

  final String apiBaseUrl;
  final String environment;

  /// True only for the `prod` launch configuration.
  ///
  /// Compared against an explicit value rather than "not dev", so a typo in ENVIRONMENT
  /// produces a dev-like build rather than an accidentally production-like one.
  bool get isProduction => environment == 'production';

  /// Whether development affordances may be shown.
  ///
  /// Checked against the environment rather than `kDebugMode` so a debug build pointed at
  /// production never exposes them.
  bool get allowsDevelopmentTools => !isProduction;
}
