import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_dart/app_reactivity.dart';

/// represents a mutable piece of state that can be:
/// - read
/// - updated
/// - observed
///
/// No UI Example:
/// ```dart
/// final counter = AppReactivityImpl<int>(0);
///
/// // Listen to changes:
/// counter.addListener(() {
///   print("Counter changed: ${counter.value}");
/// });
///
/// // Update the value:
/// counter.value = 1;
/// // Output: "Counter changed: 1"
///
/// final myListener2 = () {
///  print("Counter changed again: ${counter.value}");
/// };
/// counter.addListener(myListener2);
///
/// counter.value = 2;
/// // Output:
/// // "Counter changed: 2"
/// // "Counter changed again: 2"
///
/// // Remove one listener:
/// counter.removeListener(myListener2);
///
/// counter.value = 3;
/// // Output:
/// // "Counter changed: 3"
///
/// counter.dispose(); // when done, to clean up resources
/// ```
abstract class AppObservableReactivity<T> extends AppReactivity<T> {
  /// Updates the state with a new value.
  ///
  /// This should notify all listeners.
  ///
  /// Example:
  /// ```dart
  /// loginState.value = LoginLoading();
  /// // This should trigger all listeners to react to the new state.
  /// ```
  ///
  /// Implementation:
  /// - MUST synchronously notify listeners after change.
  /// - MUST update the value before notifying listeners.
  set value(T newValue);
}
