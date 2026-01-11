import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'bits_goals_module_platform_interface.dart';

/// An implementation of [BitsGoalsModulePlatform] that uses method channels.
class MethodChannelBitsGoalsModule extends BitsGoalsModulePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('bits_goals_module');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
