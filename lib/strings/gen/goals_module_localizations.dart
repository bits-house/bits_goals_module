// coverage:ignore-file

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'goals_module_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of GoalsModuleLocalizations
/// returned by `GoalsModuleLocalizations.of(context)`.
///
/// Applications need to include `GoalsModuleLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/goals_module_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: GoalsModuleLocalizations.localizationsDelegates,
///   supportedLocales: GoalsModuleLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the GoalsModuleLocalizations.supportedLocales
/// property.
abstract class GoalsModuleLocalizations {
  GoalsModuleLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static GoalsModuleLocalizations of(BuildContext context) {
    return Localizations.of<GoalsModuleLocalizations>(
        context, GoalsModuleLocalizations)!;
  }

  static const LocalizationsDelegate<GoalsModuleLocalizations> delegate =
      _GoalsModuleLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('pt')];

  /// Rótulo do botão de criação de meta anual de faturamento
  ///
  /// In pt, this message translates to:
  /// **'Meta Anual'**
  String get createAnnualRevenueGoalButton_label;

  /// Mensagem de sucesso exibida no AppSnackBar após criar uma meta anual de faturamento
  ///
  /// In pt, this message translates to:
  /// **'Meta de faturamento para \${year} criada! Metas mensais foram geradas e estão disponíveis para edição.'**
  String createAnnualRevenueGoalDialog_snackBar_success(int year);

  /// Título do diálogo de seleção de ano para criação de meta anual
  ///
  /// In pt, this message translates to:
  /// **'Criar meta de faturamento para:'**
  String get selectYearCreateAnnualRevenueGoalDialog_title;

  /// Subtítulo do diálogo de seleção de ano para criação de meta anual
  ///
  /// In pt, this message translates to:
  /// **'Selecione o ano'**
  String get selectYearCreateAnnualRevenueGoalDialog_subtitle;

  /// Título do diálogo de definição de meta anual, onde {year} é o ano selecionado
  ///
  /// In pt, this message translates to:
  /// **'Qual a meta de faturamento para {year}?'**
  String inputGoalTargetCreateAnnualRevenueGoalDialog_title(int year);

  /// Mensagem de erro exibida quando o valor da meta de faturamento digitado é inválido
  ///
  /// In pt, this message translates to:
  /// **'Digite um número válido.'**
  String get inputGoalTargetCreateAnnualRevenueGoalDialog_input_invalidTarget;

  /// Mensagem de erro exibida quando o valor da meta de faturamento digitado é zero ou negativo
  ///
  /// In pt, this message translates to:
  /// **'Digite um valor maior que zero.'**
  String
      get inputGoalTargetCreateAnnualRevenueGoalDialog_input_zeroOrNegativeTarget;

  /// Rótulo do campo de input do valor da meta de faturamento anual
  ///
  /// In pt, this message translates to:
  /// **'Valor da meta'**
  String get inputGoalTargetCreateAnnualRevenueGoalDialog_input_label;

  /// Rótulo do botão de confirmação para criar a meta anual de faturamento
  ///
  /// In pt, this message translates to:
  /// **'Criar'**
  String get inputGoalTargetCreateAnnualRevenueGoalDialog_createButton_label;

  /// Rótulo do botão de voltar no diálogo de criação de meta anual de faturamento
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get inputGoalTargetCreateAnnualRevenueGoalDialog_backButton_label;
}

class _GoalsModuleLocalizationsDelegate
    extends LocalizationsDelegate<GoalsModuleLocalizations> {
  const _GoalsModuleLocalizationsDelegate();

  @override
  Future<GoalsModuleLocalizations> load(Locale locale) {
    return SynchronousFuture<GoalsModuleLocalizations>(
        lookupGoalsModuleLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_GoalsModuleLocalizationsDelegate old) => false;
}

GoalsModuleLocalizations lookupGoalsModuleLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'pt':
      return GoalsModuleLocalizationsPt();
  }

  throw FlutterError(
      'GoalsModuleLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
