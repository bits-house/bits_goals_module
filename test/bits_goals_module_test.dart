import 'package:flutter_test/flutter_test.dart';
import 'package:bits_goals_module/bits_goals_module.dart';
import 'package:bits_goals_module/bits_goals_module_platform_interface.dart';
import 'package:bits_goals_module/bits_goals_module_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockBitsGoalsModulePlatform
    with MockPlatformInterfaceMixin
    implements BitsGoalsModulePlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final BitsGoalsModulePlatform initialPlatform = BitsGoalsModulePlatform.instance;

  test('$MethodChannelBitsGoalsModule is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelBitsGoalsModule>());
  });

  test('getPlatformVersion', () async {
    BitsGoalsModule bitsGoalsModulePlugin = BitsGoalsModule();
    MockBitsGoalsModulePlatform fakePlatform = MockBitsGoalsModulePlatform();
    BitsGoalsModulePlatform.instance = fakePlatform;

    expect(await bitsGoalsModulePlugin.getPlatformVersion(), '42');
  });
}
