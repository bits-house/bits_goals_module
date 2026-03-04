import 'package:bits_goals_module/src/core/domain/enums/goals_module_permission.dart';
import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_flutter/app_provider.dart';
import 'package:bits_goals_module/src/core/presentation/widgets/show_if_permitted.dart';
import 'package:bits_goals_module/src/features/goals_management/presentation/create_annual_revenue_goal/create_dialog/create_annual_revenue_goal_dialog.dart';
import 'package:flutter/material.dart';

enum _CreateAnnualRevenueGoalButtonType {
  fabLarge,
  filledButton,
}

class CreateAnnualRevenueGoalButton extends StatelessWidget {
  /// A list of years that should be unavailable for selection in the dialog
  /// when creating a new annual revenue goal. This is used to prevent creating goals
  /// for years that already have goals or are otherwise restricted.
  ///
  /// If not provided, all years will be available for selection and the use case
  /// will return a Failure if the user tries to create a goal for a year that
  /// already has one.
  final List<int>? unavailableYears;

  /// The icon to display inside the FAB. If not provided,
  /// it will default to the "add" icon.
  final IconData? iconData;

  /// The label to display next to the icon in the filled button variant. If not
  /// provided, it will use the default label from the localization strings.
  final String? label;

  /// The color of the icon and text inside the FAB. If not provided, it will use
  /// the default FAB foreground color from the current theme.
  final Color? foregroundColor;

  /// The background color of the FAB. If not provided, it will use the default FAB
  /// background color from the current theme.
  final Color? backgroundColor;

  final _CreateAnnualRevenueGoalButtonType _type;

  factory CreateAnnualRevenueGoalButton.fabLarge({
    List<int>? unavailableYears,
    IconData? iconData,
    Color? foregroundColor,
    Color? backgroundColor,
  }) {
    return CreateAnnualRevenueGoalButton._internal(
      unavailableYears: unavailableYears,
      iconData: iconData,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      type: _CreateAnnualRevenueGoalButtonType.fabLarge,
    );
  }

  factory CreateAnnualRevenueGoalButton.filledButton({
    List<int>? unavailableYears,
    IconData? iconData,
    String? label,
  }) {
    return CreateAnnualRevenueGoalButton._internal(
      unavailableYears: unavailableYears,
      iconData: iconData,
      label: label,
      type: _CreateAnnualRevenueGoalButtonType.filledButton,
    );
  }

  const CreateAnnualRevenueGoalButton._internal({
    this.unavailableYears,
    this.iconData,
    this.label,
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
    // Determine the button label, using the provided label or falling back to the
    // default localized string.
    final buttonLabel =
        label ?? context.strings.createAnnualRevenueGoalButton_label;

    // If no custom icon is provided, default to the "add" icon.
    final buttonIconData = iconData ?? Icons.add;

    return ShowIfPermitted(
      // Show the button only if the user has the required permission to
      // create annual revenue goals.
      requiredPermission: GoalsModulePermission.createAnnualRevenueGoals,

      // Depending on the button type, render the appropriate FAB variant.
      child: switch (_type) {
        _CreateAnnualRevenueGoalButtonType.fabLarge =>
          FloatingActionButton.large(
            onPressed: () => _onPressed(context: context),
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            tooltip: buttonLabel,
            child: Icon(buttonIconData),
          ),
        _CreateAnnualRevenueGoalButtonType.filledButton => FilledButton.icon(
            onPressed: () => _onPressed(context: context),
            icon: Icon(buttonIconData),
            label: Text(buttonLabel),
          ),
      },
    );
  }
}
