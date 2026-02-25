import 'package:bits_goals_module/src/core/domain/value_objects/money.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/year.dart';
import 'package:bits_goals_module/src/core/presentation/state_management/view_model/impl/app_view_model.dart';
import 'package:bits_goals_module/src/features/goals_management/application/use_cases/create_annual_revenue_goal/failures/create_annual_revenue_goal_failure.dart';
import 'package:bits_goals_module/src/features/goals_management/application/use_cases/create_annual_revenue_goal/failures/create_annual_revenue_goal_failure_reason.dart';
import 'package:dartz/dartz.dart';

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
  final double? revenueTargetInput;
  final String? revenueTargetInputErrorMessage;

  InputGoalTargetCreateAnnualRevenueGoal({
    required this.selectedYear,
    this.revenueTargetInput,
    this.revenueTargetInputErrorMessage,
  });
}

class FailureCreateAnnualRevenueGoal
    extends StatesCreateAnnualRevenueGoalDialog {
  final CreateAnnualRevenueGoalFailure failure;

  FailureCreateAnnualRevenueGoal(this.failure);
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

  final int year;
}

// ==================================================================
// ViewModel (Factory)
// ==================================================================

class CreateAnnualRevenueGoalDialogViewModel extends AppViewModel<
    StatesCreateAnnualRevenueGoalDialog, EffectsCreateAnnualRevenueGoalDialog> {
  CreateAnnualRevenueGoalDialogViewModel({
    required List<Year> unavailableYears,
  })  : _unavailableYears = unavailableYears,
        super(
          initialState: LoadingCreateAnnualRevenueGoal(),
        ) {
    initialize();
  }

  final List<Year> _unavailableYears;

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
    setState(
      SelectYearCreateAnnualRevenueGoal(
        minPossibleYear: _currentYear,
        lastPossibleYear: Year.fromInt(_currentYear.value + 1000),
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
  /// UI Validation made based on [CreateAnnualRevenueGoalFailureReason]s.
  String? _validateMoneyInput(Money input) {
    try {
      final double value = input.toDouble();
      Money.fromDouble(value);
      if (value <= 0) {
        return "Digite um valor maior que zero.";
      } else {
        return null;
      }
    } catch (e) {
      return "Digite um número válido.";
    }
  }

  Future<void> createGoal({
    required Year year,
    required Money revenueTargetInput,
  }) async {
    final errorMessage = _validateMoneyInput(revenueTargetInput);
    final isValidMoney = errorMessage == null;

    if (isValidMoney) {
      setState(LoadingCreateAnnualRevenueGoal());
      // TODO: Integrate CreateAnnualRevenueGoal use case
      final creationResult = await Future.delayed(
        const Duration(seconds: 2),
        () => const Right(null),
      );
      creationResult.fold(
        (failure) => setState(FailureCreateAnnualRevenueGoal(failure)),
        (_) => emitEffect(
          SuccessEffectCreateAnnualRevenueGoal(
            year: year.value,
          ),
        ),
      );
    } else {
      setState(
        InputGoalTargetCreateAnnualRevenueGoal(
          selectedYear: year,
          revenueTargetInput: revenueTargetInput.toDouble(),
          revenueTargetInputErrorMessage: errorMessage,
        ),
      );
    }
  }
}
