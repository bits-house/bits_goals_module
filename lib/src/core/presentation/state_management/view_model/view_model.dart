import 'dart:ui';

import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_flutter/app_streamed_list_observer.dart';
import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_flutter/app_observer.dart';
import 'package:bits_goals_module/src/core/presentation/state_management/view_model/impl/app_streamed_list_view_model.dart';

/// Defines the base contract for a ViewModel in the presentation layer.
///
/// A ViewModel is responsible for:
/// - Holding UI state
/// - Emitting UI effects (One-time events like navigation or snackbars)
/// - Coordinating state transitions through controlled methods
/// - Managing its own lifecycle
///
/// The UI must never mutate state directly.
/// All state changes must occur through ViewModel methods, ensuring the MVVM pattern
/// is preserved and the UI remains a pure function of state.
///
/// Generics:
/// - [S]: The State type (Must be a sealed class representing UI data).
/// - [E]: The Effect type (Must be a sealed class/enum representing one-off actions).
abstract interface class ViewModel<S, E> {
  /// State exposed to the UI.
  ///
  /// This represents the PERSISTENT screen/widget state (what is shown).
  /// It MUST be modeled as a sealed class with equality (== or Equatable) properly
  /// implemented for class instances, describing UI states such as:
  /// - Initial
  /// - Loading
  /// - Success(UIData)
  /// - Error(errorMessage)
  ///
  /// Rules:
  /// - MUST be read-only to the UI.
  /// - MUST be updated only through controlled methods in the ViewModel.
  /// - MUST model the entire screen state in a single sealed class.
  ///
  /// The observer widget (like [AppObserver]) listens to this property's internal
  /// observable to trigger UI rebuilds.
  ///
  /// Only expose fine-grained reactive properties by extending a custom ViewModel template, when
  /// updating the entire state would cause performance issues, like when dealing with large lists.
  /// There are built-in templates for that, like the [AppStreamedListViewModel] with
  /// [AppStreamedListObserver].
  ///
  /// If more than this [state] reactive properties is needed, consider breaking the widget into
  /// smaller ones with their own ViewModels before exposing more reactive properties through
  /// new ViewModel templates.
  S get state;

  /// Stream of side effects exposed to the UI.
  ///
  /// This represents EPHEMERAL events (what happens once), such as:
  /// - Navigation (GoToHome, Pop)
  /// - User Feedback (ShowSnackbar, ShowDialog)
  ///
  /// Why separate State from Effects?
  /// - State persists across rebuilds (e.g., screen rotation).
  /// - Effects should happen exactly once. If modeled as State, a "ShowError"
  ///   state might re-trigger the Snackbar every time the widget rebuilds or rotates,
  ///   which is undesirable.
  ///
  /// The [AppObserver] widget listens to this stream to trigger side effects without rebuilding
  /// the UI.
  Stream<E> get effects;

  /// Add a new listener that will be called whenever the state changes.
  /// [AppObserver] uses this to trigger UI rebuilds.
  void addStateListener(VoidCallback listener);

  /// Remove a previously registered state listener.
  /// [AppObserver] uses this to clean up listeners when the widget is disposed or
  /// when the ViewModel instance changes.
  void removeStateListener(VoidCallback listener);

  /// Releases all resources owned by this ViewModel.
  ///
  /// Implementations must dispose:
  /// - State reactivity
  /// - Effect controllers (StreamControllers)
  /// - Internal reactive properties
  /// - Stream subscriptions
  /// - Any external listeners
  ///
  /// Implementation example of resources to dispose:
  /// ```dart
  /// @override
  /// void dispose() {
  ///  // Dispose all reactive properties created in the ViewModel
  ///  myReactiveProperty.dispose();
  ///
  ///  // MUST call super.dispose() to clean up state listeners and effect controllers
  ///  // in the base ViewModel implementation
  ///  super.dispose();
  /// }
  /// ```
  void dispose();
}
