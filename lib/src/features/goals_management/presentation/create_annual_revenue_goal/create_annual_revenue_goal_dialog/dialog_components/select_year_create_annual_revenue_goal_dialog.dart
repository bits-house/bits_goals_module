import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_flutter/app_provider.dart';
import 'package:bits_goals_module/src/core/presentation/widgets/app_year_picker.dart';
import 'package:bits_goals_module/src/features/goals_management/presentation/create_annual_revenue_goal/create_annual_revenue_goal_dialog/create_annual_revenue_goal_dialog_store.dart';
import 'package:flutter/material.dart';

class SelectYearCreateAnnualRevenueGoalDialog extends StatelessWidget {
  const SelectYearCreateAnnualRevenueGoalDialog(
    this.state, {
    super.key,
  });

  final SelectYearCreateAnnualRevenueGoal state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = context.get<CreateAnnualRevenueGoalDialogStore>();
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
            onChanged: (int year) {
              store.onYearSelected(year);
            },
          ),
        ],
      ),
    );
  }
}
