import 'dart:io';

import 'package:flutter/foundation.dart';

class PlatformChecker {
  bool get isWeb => kIsWeb;
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isIOS => !kIsWeb && Platform.isIOS;
  String get operatingSystem => Platform.operatingSystem;
}
