import 'package:bits_goals_module/src/core/domain/enums/currency.dart';
import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_flutter/stores/impl/app_store.dart';
import 'package:bits_goals_module/src/core/presentation/utils/input_parser.dart';
import 'package:bits_goals_module/src/core/presentation/utils/ux_validate.dart';
import 'package:bits_goals_module/src/features/goals_management/application/use_cases/create_annual_revenue_goal/create_annual_revenue_goal.dart';
import 'package:bits_goals_module/src/features/goals_management/application/use_cases/create_annual_revenue_goal/create_annual_revenue_goal_params.dart';
import 'package:bits_goals_module/src/features/goals_management/application/use_cases/create_annual_revenue_goal/failures/create_annual_revenue_goal_failure.dart';
import 'package:bits_goals_module/src/features/goals_management/presentation/create_annual_revenue_goal/create_dialog/create_annual_revenue_goal_dialog.dart';

// ==================================================================
// Possible States
// ==================================================================

sealed class CreateAnnualRevenueGoalDialogState {}

// Loading
class LoadingCreateAnnualRevenueGoal
    extends CreateAnnualRevenueGoalDialogState {}

// Select the year for the annual revenue goal
class SelectYearCreateAnnualRevenueGoal
    extends CreateAnnualRevenueGoalDialogState {
  final int minPossibleYear;
  final int lastPossibleYear;
  final int preselectedYear;
  final List<int> unavailableYears;

  SelectYearCreateAnnualRevenueGoal({
    required this.minPossibleYear,
    required this.unavailableYears,
    required this.preselectedYear,
    required this.lastPossibleYear,
  });
}

// Input revenue target for the annual revenue goal
class InputGoalTargetCreateAnnualRevenueGoal
    extends CreateAnnualRevenueGoalDialogState {
  final int selectedYear;
  final String currencySymbol;
  final String? revenueTargetInput;
  final GoalRevenueTargetInputErrorReason? inputErrorReason;

  bool get enableCreateButton => inputErrorReason == null;

  InputGoalTargetCreateAnnualRevenueGoal({
    required this.selectedYear,
    required this.currencySymbol,
    this.revenueTargetInput,
    this.inputErrorReason,
  });
}

/// Meta-state for [InputGoalTargetCreateAnnualRevenueGoal] - UX reasons
enum GoalRevenueTargetInputErrorReason {
  zeroOrNegativeTarget,
  invalidTarget,
}

// Failure state when creating the annual revenue goal fails
class FailureCreateAnnualRevenueGoal
    extends CreateAnnualRevenueGoalDialogState {
  final CreateAnnualRevenueGoalFailure failure;
  final int year;

  FailureCreateAnnualRevenueGoal({
    required this.failure,
    required this.year,
  });
}

// ==================================================================
// Possible Effects
// ==================================================================

sealed class CreateAnnualRevenueGoalDialogEffect {}

// Effect emitted when the annual revenue goal is successfully created
class SuccessEffectCreateAnnualRevenueGoal
    extends CreateAnnualRevenueGoalDialogEffect {
  SuccessEffectCreateAnnualRevenueGoal({
    required this.year,
  });

  final int year;
}

//  ==================================================================
///  Store - Owned by [CreateAnnualRevenueGoalDialog]
//  ==================================================================
class CreateAnnualRevenueGoalDialogStore extends AppStore<
    CreateAnnualRevenueGoalDialogState, CreateAnnualRevenueGoalDialogEffect> {
  CreateAnnualRevenueGoalDialogStore({
    required CreateAnnualRevenueGoal useCase,
    required Currency currency,
    required List<int> unavailableYears,
  })  : _createAnnualRevenueGoal = useCase,
        _currency = currency,
        _unavailableYears = unavailableYears,
        super(
          initialState: LoadingCreateAnnualRevenueGoal(),
        ) {
    initialize();
  }
  final CreateAnnualRevenueGoal _createAnnualRevenueGoal;
  final Currency _currency;
  final List<int> _unavailableYears;

  // ---------------------------------------------------------------------
  // 1. Initialize the dialog
  // ---------------------------------------------------------------------
  final int _currentYear = DateTime.now().year;

  int _getPreselectedYear() {
    var preselectedYear = _currentYear;
    while (_unavailableYears.contains(preselectedYear)) {
      preselectedYear += 1;
    }
    return preselectedYear;
  }

  void initialize() {
    final preselectedYear = _getPreselectedYear();
    final lastPossibleYear = _currentYear + 1000;
    setState(
      SelectYearCreateAnnualRevenueGoal(
        minPossibleYear: _currentYear,
        lastPossibleYear: lastPossibleYear,
        preselectedYear: preselectedYear,
        unavailableYears: _unavailableYears,
      ),
    );
  }

  // ---------------------------------------------------------------------
  // 2. Select the year for the annual revenue goal
  // ---------------------------------------------------------------------
  void onYearSelected(int year) {
    setState(
      InputGoalTargetCreateAnnualRevenueGoal(
        selectedYear: year,
        currencySymbol: _currency.symbol,
      ),
    );
  }

  // ---------------------------------------------------------------------
  // 3. Create the annual revenue goal with the selected year and revenue target
  // ---------------------------------------------------------------------

  // Synchronous validation only for UX purposes.
  GoalRevenueTargetInputErrorReason? _validate(double? target) {
    if (target == null) {
      return GoalRevenueTargetInputErrorReason.invalidTarget;
    } else {
      return UxValidate.isMoneyGreaterThanZero(target)
          ? null
          : GoalRevenueTargetInputErrorReason.zeroOrNegativeTarget;
    }
  }

  // Clear error - UX purposes
  void onRevenueTargetInputChanged({
    required String input,
    required InputGoalTargetCreateAnnualRevenueGoal currentState,
  }) {
    if (currentState.inputErrorReason != null) {
      setState(
        InputGoalTargetCreateAnnualRevenueGoal(
          selectedYear: currentState.selectedYear,
          currencySymbol: currentState.currencySymbol,
          revenueTargetInput: input,
          inputErrorReason: null,
        ),
      );
    }
  }

  Future<void> createGoal({
    required int year,
    required String revenueTargetInput,
  }) async {
    final goalTarget = InputParser.tryParseMoneyString(
      input: revenueTargetInput,
      locale: _currency.locale,
    );
    final errorReason = _validate(goalTarget);
    final isValidInput = errorReason == null;
    if (isValidInput && goalTarget != null) {
      setState(LoadingCreateAnnualRevenueGoal());
      final creationResult = await _createAnnualRevenueGoal(
        CreateAnnualRevenueGoalParams(
          year: year,
          annualRevenueTarget: goalTarget,
          currencyISO4217Code: _currency.iso4217Code,
        ),
      );
      creationResult.fold(
        (failure) => setState(
          FailureCreateAnnualRevenueGoal(
            failure: failure,
            year: year,
          ),
        ),
        (success) => emitEffect(
          SuccessEffectCreateAnnualRevenueGoal(
            year: year,
          ),
        ),
      );
    } else {
      setState(
        InputGoalTargetCreateAnnualRevenueGoal(
          selectedYear: year,
          currencySymbol: _currency.symbol,
          revenueTargetInput: revenueTargetInput,
          inputErrorReason: errorReason,
        ),
      );
    }
  }
}
