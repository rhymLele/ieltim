import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  bool get _enabled => !kIsWeb;

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!_enabled) return;
    await FirebaseAnalytics.instance.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? _className(screenName),
    );
  }

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (!_enabled) return;
    await FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters);
  }

  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    if (!_enabled) return;
    await FirebaseAnalytics.instance.setUserProperty(name: name, value: value);
  }

  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    if (!_enabled) return;
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);
  }

  static String _className(String screenName) {
    final words = screenName
        .split(RegExp(r'[\s_\-]+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join();
    return words;
  }
}
