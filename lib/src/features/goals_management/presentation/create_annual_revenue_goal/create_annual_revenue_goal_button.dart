import 'package:bits_goals_module/src/core/application/ports/access_control_service.dart';
import 'package:bits_goals_module/src/core/domain/policies/goals_module_permission.dart';
import 'package:bits_goals_module/src/features/goals_management/presentation/create_annual_revenue_goal/create_annual_revenue_goal_dialog/create_annual_revenue_goal_dialog.dart';
import 'package:bits_goals_module/src/infra/adapters/access_control_service_impl.dart';
import 'package:bits_goals_module/src/infra/config/goals_module_config.dart';
import 'package:flutter/material.dart';

enum _CreateAnnualRevenueGoalButtonType {
  fabLarge,
}

class CreateAnnualRevenueGoalButton extends StatelessWidget {
  final GoalsModuleConfig config;
  final List<int>? unavailableYears;
  final IconData? iconData;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final _CreateAnnualRevenueGoalButtonType _type;

  factory CreateAnnualRevenueGoalButton.fabLarge({
    required GoalsModuleConfig config,
    List<int>? unavailableYears,
    IconData? iconData,
    Color? foregroundColor,
    Color? backgroundColor,
  }) {
    return CreateAnnualRevenueGoalButton._internal(
      config: config,
      unavailableYears: unavailableYears,
      iconData: iconData,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      type: _CreateAnnualRevenueGoalButtonType.fabLarge,
    );
  }

  const CreateAnnualRevenueGoalButton._internal({
    required this.config,
    this.unavailableYears,
    this.iconData,
    this.foregroundColor,
    this.backgroundColor,
    required _CreateAnnualRevenueGoalButtonType type,
  }) : _type = type;

  void _onPressed({
    required BuildContext context,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CreateAnnualRevenueGoalDialog(
          unavailableYears: unavailableYears ?? [],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Create permission Widget Wrapper
    const requiredPermission = GoalsModulePermission.createAnnualRevenueGoals;
    // TODO: Use dependency injection instead of instantiating the service directly
    final AccessControlService accessControl = AccessControlServiceImpl(config);
    final hasPermission = accessControl.hasPermission(requiredPermission);
    final buttonIconData = iconData ?? Icons.add;
    return hasPermission
        ? switch (_type) {
            _CreateAnnualRevenueGoalButtonType.fabLarge =>
              FloatingActionButton.large(
                onPressed: () => _onPressed(
                  context: context,
                ),
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                child: Icon(buttonIconData),
              ),
          }
        : const SizedBox.shrink();
  }
}
