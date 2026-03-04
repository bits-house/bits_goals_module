enum InvalidMoneyReason {
  /// The partsCount is less than 2 when attempting to split.
  invalidSplitCount,

  /// The Money.value is negative when attempting to split.
  splitNegativeCents,

  /// The currencies of the Money instances do not match when performing
  /// operations like addition or subtraction.
  currencyMismatch,
}
