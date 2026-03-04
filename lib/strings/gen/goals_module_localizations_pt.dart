// coverage:ignore-file

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'goals_module_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class GoalsModuleLocalizationsPt extends GoalsModuleLocalizations {
  GoalsModuleLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get createAnnualRevenueGoalButton_label => 'Meta Anual';

  @override
  String createAnnualRevenueGoalDialog_snackBar_success(int year) {
    return 'Meta de faturamento para \$$year criada! Metas mensais foram geradas e estão disponíveis para edição.';
  }

  @override
  String get selectYearCreateAnnualRevenueGoalDialog_title =>
      'Criar meta de faturamento para:';

  @override
  String get selectYearCreateAnnualRevenueGoalDialog_subtitle =>
      'Selecione o ano';

  @override
  String inputGoalTargetCreateAnnualRevenueGoalDialog_title(int year) {
    return 'Qual a meta de faturamento para $year?';
  }

  @override
  String get inputGoalTargetCreateAnnualRevenueGoalDialog_input_invalidTarget =>
      'Digite um número válido.';

  @override
  String
      get inputGoalTargetCreateAnnualRevenueGoalDialog_input_zeroOrNegativeTarget =>
          'Digite um valor maior que zero.';

  @override
  String get inputGoalTargetCreateAnnualRevenueGoalDialog_input_label =>
      'Valor da meta';

  @override
  String get inputGoalTargetCreateAnnualRevenueGoalDialog_createButton_label =>
      'Criar';

  @override
  String get inputGoalTargetCreateAnnualRevenueGoalDialog_backButton_label =>
      'Voltar';
}
