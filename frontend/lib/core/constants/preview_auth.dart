import 'package:flutter/foundation.dart';

/// Local UI preview only; never enables authentication on the backend.
abstract final class PreviewAuth {
  static const enabled = kDebugMode;
  static const accessKey = 'mock';
  static const token = 'local-ui-preview';
  static const userId = 'preview-user';
  static const role = 'ADMIN';
}
