import 'package:bits_goals_module/bits_goals_module.dart';
import 'package:bits_goals_module/src/core/application/ports/access_control_service.dart';
import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_flutter/app_provider.dart';
import 'package:flutter/material.dart';

class ShowIfPermitted extends StatelessWidget {
  const ShowIfPermitted({
    super.key,
    required this.child,
    required this.requiredPermission,
  });

  final Widget child;
  final GoalsModulePermission requiredPermission;

  @override
  Widget build(BuildContext context) {
    final accessControl = context.get<AccessControlService>();
    final hasPermission = accessControl.hasPermission(requiredPermission);
    return hasPermission ? child : const SizedBox.shrink();
  }
}
