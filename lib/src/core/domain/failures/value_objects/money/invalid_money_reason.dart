enum InvalidMoneyReason {
  /// The partsCount is less than 2 when attempting to split.
  invalidSplitCount,

  /// The Money.value is negative when attempting to split.
  splitNegativeCents,
}
