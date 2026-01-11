import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'bits_goals_module_method_channel.dart';

abstract class BitsGoalsModulePlatform extends PlatformInterface {
  /// Constructs a BitsGoalsModulePlatform.
  BitsGoalsModulePlatform() : super(token: _token);

  static final Object _token = Object();

  static BitsGoalsModulePlatform _instance = MethodChannelBitsGoalsModule();

  /// The default instance of [BitsGoalsModulePlatform] to use.
  ///
  /// Defaults to [MethodChannelBitsGoalsModule].
  static BitsGoalsModulePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [BitsGoalsModulePlatform] when
  /// they register themselves.
  static set instance(BitsGoalsModulePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
