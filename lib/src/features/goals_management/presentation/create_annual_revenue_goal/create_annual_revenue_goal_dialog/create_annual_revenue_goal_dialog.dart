import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_flutter/app_observer.dart';
import 'package:bits_goals_module/src/core/presentation/widgets/app_animated_dialog.dart';
import 'package:bits_goals_module/src/core/presentation/widgets/app_snack_bar.dart';
import 'package:bits_goals_module/src/features/goals_management/presentation/create_annual_revenue_goal/create_annual_revenue_goal_dialog/create_annual_revenue_goal_dialog_store.dart';
import 'package:bits_goals_module/src/features/goals_management/presentation/create_annual_revenue_goal/create_annual_revenue_goal_dialog/dialog_components/failure_create_annual_revenue_goal_dialog.dart';
import 'package:bits_goals_module/src/features/goals_management/presentation/create_annual_revenue_goal/create_annual_revenue_goal_dialog/dialog_components/input_goal_target_create_annual_revenue_goal_dialog.dart';
import 'package:bits_goals_module/src/features/goals_management/presentation/create_annual_revenue_goal/create_annual_revenue_goal_dialog/dialog_components/loading_create_annual_revenue_goal_dialog.dart';
import 'package:bits_goals_module/src/features/goals_management/presentation/create_annual_revenue_goal/create_annual_revenue_goal_dialog/dialog_components/select_year_create_annual_revenue_goal_dialog.dart';
import 'package:flutter/material.dart';

class CreateAnnualRevenueGoalDialog extends StatelessWidget {
  const CreateAnnualRevenueGoalDialog({
    super.key,
    required this.unavailableYears,
  });

  final List<int> unavailableYears;

  /// [Key] only needed by [AppAnimatedDialog] for custom animation state reasons
  Widget _buildByState(CreateAnnualRevenueGoalDialogStates state) {
    switch (state) {
      case LoadingCreateAnnualRevenueGoal():
        return const LoadingCreateAnnualRevenueGoalDialog(
          key: Key("loading_create_annual_revenue_goal_dialog"),
        );
      case SelectYearCreateAnnualRevenueGoal():
        return SelectYearCreateAnnualRevenueGoalDialog(
          state,
          key: const Key("select_year_create_annual_revenue_goal_dialog"),
        );
      case InputGoalTargetCreateAnnualRevenueGoal():
        return InputGoalTargetCreateAnnualRevenueGoalDialog(
          state,
          key: const Key("input_goal_target_create_annual_revenue_goal_dialog"),
        );
      case FailureCreateAnnualRevenueGoal():
        return FailureCreateAnnualRevenueGoalDialog(
          state,
          key: const Key("failure_create_annual_revenue_goal_dialog"),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the use case instance from the context using AppProvider (dependency injection)
    // final CreateAnnualRevenueGoal useCase =
    //     context.get<CreateAnnualRevenueGoal>();

    // Provide the store to the AppObserver, which will rebuild the UI based on the store
    // states and handle effects
    return AppObserver<
        CreateAnnualRevenueGoalDialogStore,
        CreateAnnualRevenueGoalDialogStates,
        CreateAnnualRevenueGoalDialogEffects>(
      store: CreateAnnualRevenueGoalDialogStore(
        // useCase: useCase,
        unavailableYears: unavailableYears,
      ),

      // The builder function is called automatically whenever the state changes
      builder: (context, state) {
        // [AppAnimatedDialog] is the main [Dialog], that ensures smooth transitions between
        // the current [child] and the next [child], based on the [state].
        // **UX purpose only**.
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
              // TODO: Internacionalizar
              content: Text(
                "Meta de faturamento para ${effect.year} criada! Metas mensais foram geradas e estão disponíveis para edição.",
              ),
            ),
          );
        }
      },
    );
  }
}
