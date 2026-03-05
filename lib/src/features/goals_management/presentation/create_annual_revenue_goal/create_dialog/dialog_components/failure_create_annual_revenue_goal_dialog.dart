import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_flutter/app_provider.dart';
import 'package:bits_goals_module/src/features/goals_management/application/use_cases/create_annual_revenue_goal/failures/create_annual_revenue_goal_failure_reason.dart';
import 'package:bits_goals_module/src/features/goals_management/presentation/create_annual_revenue_goal/create_dialog/create_annual_revenue_goal_dialog_store.dart';
import 'package:flutter/material.dart';

class FailureCreateAnnualRevenueGoalDialog extends StatelessWidget {
  const FailureCreateAnnualRevenueGoalDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final store = context.get<CreateAnnualRevenueGoalDialogStore>();
    final state = store.state as FailureCreateAnnualRevenueGoal;
    final strings = context.strings;
    final retryAfterMinutes = state.failure.retryAfter != null
        ? state.failure.retryAfter!.inMinutes
        : 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.failureCreateAnnualRevenueGoalDialog_title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),
          Text(
            switch (state.failure.reason) {
              CreateAnnualRevenueGoalFailureReason
                    .annualGoalForYearAlreadyExists =>
                strings
                    .failureCreateAnnualRevenueGoalDialog_message_annualGoalForYearAlreadyExists(
                        state.year),
              CreateAnnualRevenueGoalFailureReason.unexpected =>
                strings.failureCreateAnnualRevenueGoalDialog_message_unexpected,
              CreateAnnualRevenueGoalFailureReason.connectionError => strings
                  .failureCreateAnnualRevenueGoalDialog_message_connectionError,
              CreateAnnualRevenueGoalFailureReason.pastYear =>
                strings.failureCreateAnnualRevenueGoalDialog_message_pastYear,
              CreateAnnualRevenueGoalFailureReason.permissionDenied => strings
                  .failureCreateAnnualRevenueGoalDialog_message_permissionDenied,
              CreateAnnualRevenueGoalFailureReason.rateLimitExceeded => strings
                  .failureCreateAnnualRevenueGoalDialog_message_rateLimitExceeded(
                      retryAfterMinutes),
              CreateAnnualRevenueGoalFailureReason.zeroOrNegativeTarget => strings
                  .failureCreateAnnualRevenueGoalDialog_message_zeroOrNegativeTarget,
            },
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                onPressed: () {
                  store.initialize();
                },
                child: Text(
                  strings
                      .failureCreateAnnualRevenueGoalDialog_retryButton_label,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
