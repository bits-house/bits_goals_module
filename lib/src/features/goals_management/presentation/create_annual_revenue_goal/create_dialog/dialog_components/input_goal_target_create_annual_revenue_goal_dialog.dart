import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_flutter/app_provider.dart';
import 'package:bits_goals_module/src/features/goals_management/presentation/create_annual_revenue_goal/create_dialog/create_annual_revenue_goal_dialog_store.dart';
import 'package:flutter/material.dart';

class InputGoalTargetCreateAnnualRevenueGoalDialog extends StatefulWidget {
  const InputGoalTargetCreateAnnualRevenueGoalDialog(
    this.state, {
    super.key,
  });

  final InputGoalTargetCreateAnnualRevenueGoal state;

  @override
  State<InputGoalTargetCreateAnnualRevenueGoalDialog> createState() =>
      _InputGoalTargetCreateAnnualRevenueGoalDialogState();
}

class _InputGoalTargetCreateAnnualRevenueGoalDialogState
    extends State<InputGoalTargetCreateAnnualRevenueGoalDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.state.revenueTargetInput,
    );
    _focusNode = FocusNode();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.get<CreateAnnualRevenueGoalDialogStore>();
    final strings = context.strings;
    final errorReason = widget.state.inputErrorReason;

    // Strings
    final dialogTitleString =
        strings.inputGoalTargetCreateAnnualRevenueGoalDialog_title(
      widget.state.selectedYear,
    );
    final inputErrorString = switch (errorReason) {
      GoalRevenueTargetInputErrorReason.invalidTarget => strings
          .inputGoalTargetCreateAnnualRevenueGoalDialog_input_invalidTarget,
      GoalRevenueTargetInputErrorReason.zeroOrNegativeTarget => strings
          .inputGoalTargetCreateAnnualRevenueGoalDialog_input_zeroOrNegativeTarget,
      null => null,
    };
    final inputLabelString =
        strings.inputGoalTargetCreateAnnualRevenueGoalDialog_input_label;
    final inputPrefixString = '${widget.state.currencySymbol} ';
    final createButtonString =
        strings.inputGoalTargetCreateAnnualRevenueGoalDialog_createButton_label;
    final backButtonString =
        strings.inputGoalTargetCreateAnnualRevenueGoalDialog_backButton_label;

    // UI
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dialogTitleString,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),
          TextField(
            focusNode: _focusNode,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: inputLabelString,
              prefixText: inputPrefixString,
              errorText: inputErrorString,
            ),
            controller: _controller,
            onChanged: (input) => store.onRevenueTargetInputChanged(
              input: input,
              currentState: widget.state,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  store.initialize();
                },
                child: Text(backButtonString),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: widget.state.enableCreateButton
                    ? () {
                        store.createGoal(
                          year: widget.state.selectedYear,
                          revenueTargetInput: _controller.text,
                        );
                      }
                    : null,
                child: Text(createButtonString),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
