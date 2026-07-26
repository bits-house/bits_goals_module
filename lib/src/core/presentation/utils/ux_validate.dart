/// [UxValidate] provides static methods that offer synchronous validation
/// logic for various types of data, for User Experience (UX) purposes.
class UxValidate {
  // TODO: Add unit tests for this class.
  static bool isDoubleGreaterThanZero(double value) {
    return value.isFinite && value > 0;
  }
}
