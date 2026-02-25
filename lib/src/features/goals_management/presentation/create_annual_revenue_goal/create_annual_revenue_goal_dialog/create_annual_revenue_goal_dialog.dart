import 'package:bits_goals_module/src/core/domain/value_objects/year.dart';
import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_flutter/app_observer.dart';
import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_flutter/app_provider.dart';
import 'package:bits_goals_module/src/core/presentation/widgets/app_animated_dialog.dart';
import 'package:bits_goals_module/src/features/goals_management/application/use_cases/create_annual_revenue_goal/create_annual_revenue_goal.dart';
import 'package:bits_goals_module/src/features/goals_management/presentation/create_annual_revenue_goal/create_annual_revenue_goal_dialog/create_annual_revenue_goal_dialog_view_model.dart';
import 'package:bits_goals_module/src/features/goals_management/presentation/create_annual_revenue_goal/create_annual_revenue_goal_dialog/dialog_compoments/failure_create_annual_revenue_goal_dialog.dart';
import 'package:bits_goals_module/src/features/goals_management/presentation/create_annual_revenue_goal/create_annual_revenue_goal_dialog/dialog_compoments/input_goal_target_create_annual_revenue_goal_dialog.dart';
import 'package:bits_goals_module/src/features/goals_management/presentation/create_annual_revenue_goal/create_annual_revenue_goal_dialog/dialog_compoments/loading_create_annual_revenue_goal_dialog.dart';
import 'package:bits_goals_module/src/features/goals_management/presentation/create_annual_revenue_goal/create_annual_revenue_goal_dialog/dialog_compoments/select_year_create_annual_revenue_goal_dialog.dart';
import 'package:flutter/material.dart';

class CreateAnnualRevenueGoalDialog extends StatelessWidget {
  const CreateAnnualRevenueGoalDialog({
    super.key,
    required this.unavailableYears,
  });

  final List<Year> unavailableYears;

  Widget _buildByState(StatesCreateAnnualRevenueGoalDialog state) {
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
    final CreateAnnualRevenueGoal useCase =
        context.get<CreateAnnualRevenueGoal>();
    return AppObserver<
        CreateAnnualRevenueGoalDialogViewModel,
        StatesCreateAnnualRevenueGoalDialog,
        EffectsCreateAnnualRevenueGoalDialog>(
      viewModel: CreateAnnualRevenueGoalDialogViewModel(
        useCase: useCase,
        unavailableYears: unavailableYears,
      ),
      builder: (context, state) {
        return AppAnimatedDialog(
          child: _buildByState(state),
        );
      },
      onEffect: (context, effect) {
        if (effect is SuccessEffectCreateAnnualRevenueGoal) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            // TODO: AppSnackbar com timer bar para a duration
            SnackBar(
              showCloseIcon: true,
              duration: const Duration(seconds: 15),
              backgroundColor: Theme.of(context).colorScheme.primary,
              content: Text(
                "Meta de faturamento para ${effect.year.value} criada! Metas mensais foram geradas e estão disponíveis para edição.",
              ),
            ),
          );
        }
      },
    );
  }
}
