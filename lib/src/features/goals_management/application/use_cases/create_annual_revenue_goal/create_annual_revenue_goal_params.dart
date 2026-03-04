class CreateAnnualRevenueGoalParams {
  /// The calendar year this goal applies to (e.g. 2026)
  final int year;

  /// The target annual revenue amount
  final double annualRevenueTarget;

  /// The ISO 4217 currency code for the target (e.g. BRL)
  final String currencyISO4217Code;

  const CreateAnnualRevenueGoalParams({
    required this.year,
    required this.annualRevenueTarget,
    required this.currencyISO4217Code,
  });
}
