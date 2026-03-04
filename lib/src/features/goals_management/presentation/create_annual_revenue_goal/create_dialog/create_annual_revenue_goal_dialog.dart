import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_flutter/app_observer.dart';
import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_flutter/app_provider.dart';
import 'package:bits_goals_module/src/core/presentation/widgets/app_animated_dialog.dart';
import 'package:bits_goals_module/src/core/presentation/widgets/app_snack_bar.dart';
import 'package:bits_goals_module/src/features/goals_management/presentation/create_annual_revenue_goal/create_dialog/create_annual_revenue_goal_dialog_store.dart';
import 'package:bits_goals_module/src/features/goals_management/presentation/create_annual_revenue_goal/create_dialog/dialog_components/failure_create_annual_revenue_goal_dialog.dart';
import 'package:bits_goals_module/src/features/goals_management/presentation/create_annual_revenue_goal/create_dialog/dialog_components/input_goal_target_create_annual_revenue_goal_dialog.dart';
import 'package:bits_goals_module/src/features/goals_management/presentation/create_annual_revenue_goal/create_dialog/dialog_components/loading_create_annual_revenue_goal_dialog.dart';
import 'package:bits_goals_module/src/features/goals_management/presentation/create_annual_revenue_goal/create_dialog/dialog_components/select_year_create_annual_revenue_goal_dialog.dart';
import 'package:flutter/material.dart';

import '../../../../../infra/config/goals_module_config.dart';

class CreateAnnualRevenueGoalDialog extends StatelessWidget {
  const CreateAnnualRevenueGoalDialog({
    super.key,
    required this.unavailableYears,
  });

  final List<int> unavailableYears;

  /// [Key] is only required by [AppAnimatedDialog] for UI custom animation purposes,
  /// it is NOT related to AppObserver/Store state management.
  Widget _buildByState(CreateAnnualRevenueGoalDialogState state) {
    switch (state) {
      case LoadingCreateAnnualRevenueGoal():
        return const LoadingCreateAnnualRevenueGoalDialog(
          key: Key("loading_create_annual_revenue_goal_dialog"),
        );
      case SelectYearCreateAnnualRevenueGoal():
        return const SelectYearCreateAnnualRevenueGoalDialog(
          key: Key("select_year_create_annual_revenue_goal_dialog"),
        );
      case InputGoalTargetCreateAnnualRevenueGoal():
        return InputGoalTargetCreateAnnualRevenueGoalDialog(
          state,
          key: const Key("input_goal_target_create_annual_revenue_goal_dialog"),
        );
      case FailureCreateAnnualRevenueGoal():
        return const FailureCreateAnnualRevenueGoalDialog(
          key: Key("failure_create_annual_revenue_goal_dialog"),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the current currency from the Host App, to be used in
    // this creation UI/use case/persistence.
    final config = context.get<GoalsModuleConfig>();
    final currency = config.getCurrentCurrency();

    // Get the use case instance.
    // final CreateAnnualRevenueGoal useCase =
    //     context.get<CreateAnnualRevenueGoal>();

    // Get Success AppSnackBar string (internationalization).
    final strings = context.strings;
    final snackBarSuccessString =
        strings.createAnnualRevenueGoalDialog_snackBar_success;

    return AppObserver<
        CreateAnnualRevenueGoalDialogStore,
        CreateAnnualRevenueGoalDialogState,
        CreateAnnualRevenueGoalDialogEffect>(
      // Provide the store to the AppObserver, which will rebuild the UI based on the store
      // states, handle emitted effects, provide the store to the widget tree (dependency
      // injection), and dispose the Store when this widget is removed from the tree.
      store: CreateAnnualRevenueGoalDialogStore(
        // useCase: useCase,
        currency: currency,
        unavailableYears: unavailableYears,
      ),

      // The builder function is called automatically whenever the state changes.
      builder: (context, state) {
        return AppAnimatedDialog(
          child: _buildByState(state),
        );
      },

      // The onEffect function is called automatically whenever an effect is emitted by
      // the store.
      onEffect: (context, effect) {
        if (effect is SuccessEffectCreateAnnualRevenueGoal) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            AppSnackBar.build(
              context: context,
              content: Text(
                snackBarSuccessString(effect.year),
              ),
            ),
          );
        }
      },
    );
  }
}
