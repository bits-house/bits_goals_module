/// Reasons for failure when creating an annual revenue goal
///
/// Used to doc and express the use case expected validations.
/// Also, used to map to user-friendly error messages in
/// presentation layer.
enum CreateAnnualRevenueGoalFailureReason {
  /// Thrown when trying to create a goal for a
  /// year that is in the past
  pastYear,

  zeroOrNegativeTarget,

  annualGoalForYearAlreadyExists,

  permissionDenied,

  unexpected,

  connectionError,
}
