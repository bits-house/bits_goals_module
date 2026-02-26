/// A framework-agnostic reactive state holder.
///
/// It is the bridge between the UI and Store with any underlying
/// reactivity system (MobX, Signals, Streams, ValueNotifier, etc).
///
/// The UI should never depend on a specific framework.
abstract class AppReactivity<T> {
  /// The current value of the reactive state.
  ///
  /// Use this to read the latest state.
  ///
  /// Example:
  /// ```dart
  /// if (loginState.value is LoginLoading) {
  ///   showSpinner();
  /// }
  /// ```
  T get value;

  /// Registers a listener that will be called whenever the value changes.
  ///
  /// Used by UI widgets (like ReactiveBuilder) to rebuild automatically.
  ///
  /// Example:
  /// ```dart
  /// final myListener = () {
  ///   print("Login state changed: ${loginState.value}");
  /// };
  /// loginState.addListener(myListener);
  /// // This will be called whenever loginState.value changes.
  /// ```
  ///
  /// Implementation:
  /// - MUST be called synchronously when value changes.
  void addListener(void Function() listener);

  /// Removes a previously registered listener.
  ///
  /// This should be called when the observer is destroyed
  /// (e.g. in Widget.dispose) to avoid memory leaks.
  ///
  /// Example:
  /// ```dart
  /// loginState.removeListener(myListener);
  /// ```
  ///
  /// Implementation:
  /// - MUST prevent future notifications.
  void removeListener(void Function() listener);

  /// Releases any internal resources.
  ///
  /// IMPORTANT:
  /// This should be called by whoever OWNS the state
  /// (typically a Store / Presenter),
  /// not by UI listeners.
  ///
  /// Example:
  /// ```dart
  /// class LoginStore {
  ///   final email = AppReactivityImpl<String>("");
  ///
  ///   void dispose() {
  ///     email.dispose();
  ///   }
  /// }
  /// ```
  ///
  /// Implementation - After dispose:
  /// - no listeners are called
  /// - setting value is ignored
  void dispose();
}
