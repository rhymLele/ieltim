import 'package:flutter/foundation.dart';

/// Select with --dart-define=APP_ENV=test|dev|product.
/// The string value of each environment is available through [name].
enum AppEnv {
  test,
  dev,
  product;

  static final AppEnv current = AppEnv.values.byName(
    const String.fromEnvironment(
      'APP_ENV',
      defaultValue: kReleaseMode ? 'product' : 'dev',
    ),
  );

  /// API_BASE_URL overrides the default URL for the selected environment.
  String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;

    return switch (this) {
      AppEnv.dev => 'http://localhost:3000/api',
      AppEnv.product => 'https://ieltim.onrender.com/api',
      AppEnv.test => throw StateError(
        'APP_ENV=test requires --dart-define=API_BASE_URL=<test API URL>.',
      ),
    };
  }
}
