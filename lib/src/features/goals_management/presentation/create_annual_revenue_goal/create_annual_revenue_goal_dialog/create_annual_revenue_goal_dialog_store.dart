import 'package:bits_goals_module/src/core/presentation/state_management/app_stores/impl/app_store.dart';
import 'package:bits_goals_module/src/features/goals_management/application/use_cases/create_annual_revenue_goal/failures/create_annual_revenue_goal_failure.dart';
import 'package:bits_goals_module/src/features/goals_management/application/use_cases/create_annual_revenue_goal/failures/create_annual_revenue_goal_failure_reason.dart';
import 'package:bits_goals_module/src/features/goals_management/presentation/create_annual_revenue_goal/create_annual_revenue_goal_dialog/create_annual_revenue_goal_dialog.dart';
import 'package:dartz/dartz.dart';

// ==================================================================
// Possible States
// ==================================================================

sealed class CreateAnnualRevenueGoalDialogStates {}

// Loading
class LoadingCreateAnnualRevenueGoal
    extends CreateAnnualRevenueGoalDialogStates {}

// Select the year for the annual revenue goal
class SelectYearCreateAnnualRevenueGoal
    extends CreateAnnualRevenueGoalDialogStates {
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
    extends CreateAnnualRevenueGoalDialogStates {
  final int selectedYear;
  final String? revenueTargetInput;
  final GoalRevenueTargetInputErrorReason? inputErrorReason;

  bool get enableCreateButton => revenueTargetInput != null;

  InputGoalTargetCreateAnnualRevenueGoal({
    required this.selectedYear,
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
    extends CreateAnnualRevenueGoalDialogStates {
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

sealed class CreateAnnualRevenueGoalDialogEffects {}

// Effect emitted when the annual revenue goal is successfully created
class SuccessEffectCreateAnnualRevenueGoal
    extends CreateAnnualRevenueGoalDialogEffects {
  SuccessEffectCreateAnnualRevenueGoal({
    required this.year,
  });

  final int year;
}

//  ==================================================================
///  Store - Owned by [CreateAnnualRevenueGoalDialog]
//  ==================================================================
class CreateAnnualRevenueGoalDialogStore extends AppStore<
    CreateAnnualRevenueGoalDialogStates, CreateAnnualRevenueGoalDialogEffects> {
  CreateAnnualRevenueGoalDialogStore({
    required List<int> unavailableYears,
    // required CreateAnnualRevenueGoal useCase,
  })  : _unavailableYears = unavailableYears,
        // _createAnnualRevenueGoal = useCase,
        super(
          initialState: LoadingCreateAnnualRevenueGoal(),
        ) {
    initialize();
  }

  final List<int> _unavailableYears;
  // final CreateAnnualRevenueGoal _createAnnualRevenueGoal;

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
      ),
    );
  }

  // ---------------------------------------------------------------------
  // 3. Create the annual revenue goal with the selected year and revenue target
  // ---------------------------------------------------------------------

  // Synchronous validation only for UX purposes.
  GoalRevenueTargetInputErrorReason? _validateMoneyInput(
    String input,
  ) {
    try {
      final double value = double.parse(input);
      if (value <= 0) {
        return GoalRevenueTargetInputErrorReason.zeroOrNegativeTarget;
      } else {
        return null;
      }
    } catch (e) {
      return GoalRevenueTargetInputErrorReason.invalidTarget;
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
    final errorReason = _validateMoneyInput(
      revenueTargetInput,
    );
    final isValidMoney = errorReason == null;
    if (isValidMoney) {
      setState(LoadingCreateAnnualRevenueGoal());

      // -------------------------------------------------------------------------
      // TODO: use use case
      final creationResult = await Future.delayed(
        const Duration(seconds: 1),
        () => const Left(
          CreateAnnualRevenueGoalFailure(
            reason: CreateAnnualRevenueGoalFailureReason.zeroOrNegativeTarget,
          ),
        ),
      );
      // -------------------------------------------------------------------------

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
          revenueTargetInput: revenueTargetInput,
          inputErrorReason: errorReason,
        ),
      );
    }
  }
}
