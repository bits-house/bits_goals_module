import 'package:bits_goals_module/src/core/domain/value_objects/money.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/year.dart';
import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_flutter/app_observer.dart';
import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_flutter/app_provider.dart';
import 'package:bits_goals_module/src/core/presentation/widgets/app_year_picker.dart';
import 'package:bits_goals_module/src/core/presentation/widgets/dialog_animated_wrapper.dart';
import 'package:bits_goals_module/src/features/goals_management/presentation/create_annual_revenue_goal/create_annual_revenue_goal_dialog/create_annual_revenue_goal_dialog_view_model.dart';
import 'package:flutter/material.dart';

class CreateAnnualRevenueGoalDialog extends StatelessWidget {
  const CreateAnnualRevenueGoalDialog({
    super.key,
  });

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
    return AppObserver<
        CreateAnnualRevenueGoalDialogViewModel,
        StatesCreateAnnualRevenueGoalDialog,
        EffectsCreateAnnualRevenueGoalDialog>(
      viewModel: CreateAnnualRevenueGoalDialogViewModel(
        unavailableYears: <Year>[
          Year.fromInt(2026),
        ],
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
                "Meta de faturamento para ${effect.year} criada! Metas mensais foram geradas e estão disponíveis para edição.",
              ),
            ),
          );
        }
      },
    );
  }
}

class LoadingCreateAnnualRevenueGoalDialog extends StatelessWidget {
  const LoadingCreateAnnualRevenueGoalDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(64),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
        ],
      ),
    );
  }
}

class SelectYearCreateAnnualRevenueGoalDialog extends StatelessWidget {
  const SelectYearCreateAnnualRevenueGoalDialog(
    this.state, {
    super.key,
  });

  final SelectYearCreateAnnualRevenueGoal state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.get<CreateAnnualRevenueGoalDialogViewModel>();
    final titleString =
        context.strings.selectYearCreateAnnualRevenueGoalDialog_title;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            titleString,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          AppYearPicker(
            firstYear: state.minPossibleYear,
            lastYear: state.lastPossibleYear,
            preSelectedYear: state.preselectedYear,
            unavailableYears: state.unavailableYears,
            onChanged: (Year year) {
              viewModel.onYearSelected(year);
            },
          ),
        ],
      ),
    );
  }
}

class InputGoalTargetCreateAnnualRevenueGoalDialog extends StatelessWidget {
  const InputGoalTargetCreateAnnualRevenueGoalDialog(
    this.state, {
    super.key,
  });

  final InputGoalTargetCreateAnnualRevenueGoal state;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.get<CreateAnnualRevenueGoalDialogViewModel>();
    final titleString =
        context.strings.inputGoalTargetCreateAnnualRevenueGoalDialog_title(
      state.selectedYear.value,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            titleString,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),
          TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Valor da meta",
              prefixText: "R\$ ",
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  viewModel.initialize();
                },
                child: Text("Voltar"),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  viewModel.createGoal(
                    year: state.selectedYear,
                    revenueTargetInput: Money.fromDouble(10000.00),
                  );
                },
                child: Text("Criar"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FailureCreateAnnualRevenueGoalDialog extends StatelessWidget {
  const FailureCreateAnnualRevenueGoalDialog(
    this.state, {
    super.key,
  });

  final FailureCreateAnnualRevenueGoal state;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.get<CreateAnnualRevenueGoalDialogViewModel>();
    return Text('Erro');
  }
}
