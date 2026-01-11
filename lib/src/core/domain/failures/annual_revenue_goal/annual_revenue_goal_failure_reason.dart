enum AnnualRevenueGoalFailureReason {
  /// An annual revenue goal must have exactly 12 monthly goals
  invalidMonthsCount,

  /// Monthly goals must have unique months within the same year
  duplicateMonth,

  /// All monthly goals must belong to the same year as the annual goal
  yearMismatch,

  /// One or more monthly revenue goals are invalid
  invalidMonthlyRevenueGoal,

  /// The annual revenue target must be greater than zero
  zeroOrNegativeAnnualGoal,
}
