// coverage:ignore-file

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

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
}
