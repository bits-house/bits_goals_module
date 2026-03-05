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

  @override
  String get failureCreateAnnualRevenueGoalDialog_title => 'Erro ao criar';

  @override
  String get failureCreateAnnualRevenueGoalDialog_retryButton_label =>
      'Tentar novamente';

  @override
  String
      failureCreateAnnualRevenueGoalDialog_message_annualGoalForYearAlreadyExists(
          int year) {
    return 'Já existe uma meta anual para $year. Selecione outro ano ou edite a meta existente.';
  }

  @override
  String get failureCreateAnnualRevenueGoalDialog_message_unexpected =>
      'Ocorreu um erro inesperado. Tente novamente.';

  @override
  String get failureCreateAnnualRevenueGoalDialog_message_connectionError =>
      'Ocorreu um erro de conexão. Verifique sua internet e tente novamente.';

  @override
  String get failureCreateAnnualRevenueGoalDialog_message_pastYear =>
      'Não é possível criar meta para um ano passado. Selecione outro ano.';

  @override
  String get failureCreateAnnualRevenueGoalDialog_message_permissionDenied =>
      'Você não possui permissão para criar metas anuais. Solicite com o administrador.';

  @override
  String failureCreateAnnualRevenueGoalDialog_message_rateLimitExceeded(
      int retryAfterMinutes) {
    String _temp0 = intl.Intl.pluralLogic(
      retryAfterMinutes,
      locale: localeName,
      other: '$retryAfterMinutes minutos',
      one: '1 minuto',
      zero: 'alguns instantes',
    );
    return 'Muitas tentativas. Tente novamente em $_temp0.';
  }

  @override
  String
      get failureCreateAnnualRevenueGoalDialog_message_zeroOrNegativeTarget =>
          'O valor da meta deve ser maior que zero.';
}
