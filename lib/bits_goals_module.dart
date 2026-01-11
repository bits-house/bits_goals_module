
import 'bits_goals_module_platform_interface.dart';

class BitsGoalsModule {
  Future<String?> getPlatformVersion() {
    return BitsGoalsModulePlatform.instance.getPlatformVersion();
  }
}
