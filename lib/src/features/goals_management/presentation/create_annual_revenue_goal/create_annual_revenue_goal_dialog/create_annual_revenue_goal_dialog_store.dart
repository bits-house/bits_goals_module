import 'package:bits_goals_module/src/core/domain/value_objects/money.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/year.dart';
import 'package:bits_goals_module/src/core/presentation/state_management/store/impl/app_store.dart';
import 'package:bits_goals_module/src/features/goals_management/application/use_cases/create_annual_revenue_goal/create_annual_revenue_goal.dart';
import 'package:bits_goals_module/src/features/goals_management/application/use_cases/create_annual_revenue_goal/failures/create_annual_revenue_goal_failure.dart';
import 'package:bits_goals_module/src/features/goals_management/application/use_cases/create_annual_revenue_goal/failures/create_annual_revenue_goal_failure_reason.dart';
import 'package:dartz/dartz.dart';

// ==================================================================
// Meta-states
// ==================================================================

enum GoalRevenueTargetInputErrorReason {
  zeroOrNegativeTarget,
  invalidTarget,
}

// ==================================================================
// States
// ==================================================================

sealed class StatesCreateAnnualRevenueGoalDialog {}

class LoadingCreateAnnualRevenueGoal
    extends StatesCreateAnnualRevenueGoalDialog {}

class SelectYearCreateAnnualRevenueGoal
    extends StatesCreateAnnualRevenueGoalDialog {
  final Year minPossibleYear;
  final Year lastPossibleYear;
  final Year preselectedYear;
  final List<Year> unavailableYears;

  SelectYearCreateAnnualRevenueGoal({
    required this.minPossibleYear,
    required this.unavailableYears,
    required this.preselectedYear,
    required this.lastPossibleYear,
  });
}

class InputGoalTargetCreateAnnualRevenueGoal
    extends StatesCreateAnnualRevenueGoalDialog {
  final Year selectedYear;
  final String? revenueTargetInput;
  final GoalRevenueTargetInputErrorReason? inputErrorReason;

  bool get enableCreateButton => revenueTargetInput != null;

  InputGoalTargetCreateAnnualRevenueGoal({
    required this.selectedYear,
    this.revenueTargetInput,
    this.inputErrorReason,
  });
}

class FailureCreateAnnualRevenueGoal
    extends StatesCreateAnnualRevenueGoalDialog {
  final CreateAnnualRevenueGoalFailure failure;
  final Year year;

  FailureCreateAnnualRevenueGoal({
    required this.failure,
    required this.year,
  });
}

// ==================================================================
// Effects
// ==================================================================

sealed class EffectsCreateAnnualRevenueGoalDialog {}

class SuccessEffectCreateAnnualRevenueGoal
    extends EffectsCreateAnnualRevenueGoalDialog {
  SuccessEffectCreateAnnualRevenueGoal({
    required this.year,
  });

  final Year year;
}

// ==================================================================
// Store (Factory)
// ==================================================================

class CreateAnnualRevenueGoalDialogStore extends AppStore<
    StatesCreateAnnualRevenueGoalDialog, EffectsCreateAnnualRevenueGoalDialog> {
  CreateAnnualRevenueGoalDialogStore({
    required List<Year> unavailableYears,
    required CreateAnnualRevenueGoal useCase,
  })  : _unavailableYears = unavailableYears,
        _createAnnualRevenueGoal = useCase,
        super(
          initialState: LoadingCreateAnnualRevenueGoal(),
        ) {
    initialize();
  }

  final List<Year> _unavailableYears;
  final CreateAnnualRevenueGoal _createAnnualRevenueGoal;

  // ---------------------------------------------------------------------
  // 1. Initialize the dialog
  // ---------------------------------------------------------------------

  final Year _currentYear = Year.fromInt(DateTime.now().year);

  Year _getPreselectedYear() {
    var preselectedYear = _currentYear;
    while (_unavailableYears.contains(preselectedYear)) {
      preselectedYear = Year.fromInt(preselectedYear.value + 1);
    }
    return preselectedYear;
  }

  void initialize() {
    final preselectedYear = _getPreselectedYear();
    final lastPossibleYear = Year.fromInt(_currentYear.value + 1000);
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
  void onYearSelected(Year year) {
    setState(
      InputGoalTargetCreateAnnualRevenueGoal(
        selectedYear: year,
      ),
    );
  }

  // ---------------------------------------------------------------------
  // 3. Create the annual revenue goal with the selected year and revenue target
  // ---------------------------------------------------------------------
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

  GoalRevenueTargetInputErrorReason? _validateMoneyInput(
    String input,
  ) {
    try {
      final double value = double.parse(input);
      Money.fromDouble(value);
      if (value <= 0) {
        return GoalRevenueTargetInputErrorReason.zeroOrNegativeTarget;
      } else {
        return null;
      }
    } catch (e) {
      return GoalRevenueTargetInputErrorReason.invalidTarget;
    }
  }

  Future<void> createGoal({
    required Year year,
    required String revenueTargetInput,
  }) async {
    final errorReason = _validateMoneyInput(
      revenueTargetInput,
    );
    final isValidMoney = errorReason == null;
    if (isValidMoney) {
      setState(LoadingCreateAnnualRevenueGoal());
      // use _createAnnualRevenueGoal()
      final creationResult = await Future.delayed(
        const Duration(seconds: 1),
        () => const Left(
          CreateAnnualRevenueGoalFailure(
            reason: CreateAnnualRevenueGoalFailureReason.zeroOrNegativeTarget,
          ),
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
          revenueTargetInput: revenueTargetInput,
          inputErrorReason: errorReason,
        ),
      );
    }
  }
}
