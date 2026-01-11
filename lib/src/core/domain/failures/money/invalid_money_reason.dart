enum InvalidMoneyReason {
  /// The split count is invalid (e.g., less than 1).
  /// Used when trying to split money into parts.
  invalidSplitCount,

  /// The money value is negative (less than zero).
  splitNegativeCents,
}
