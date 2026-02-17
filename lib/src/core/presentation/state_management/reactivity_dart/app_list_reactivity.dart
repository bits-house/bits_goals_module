import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_dart/app_observable_reactivity.dart';
import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_dart/app_reactivity.dart';

/// A specialized reactive state holder for lists.
///
/// `AppListReactivity<T>` represents a mutable reactive collection of items
/// that can be:
/// - read as a full list
/// - structurally modified (add/remove/clear/replace)
/// - observed for changes
///
/// It extends [AppReactivity<List<T>>], preserving the same reactive guarantees,
/// while providing semantic operations for list mutation.
///
/// The goal is to avoid exposing raw list mutation (like `list.add`)
/// and instead ensure all structural changes go through controlled,
/// observable operations.
///
/// Example mental model:
/// Think of this as a "reactive list box".
/// You can:
///   - see the full list
///   - insert items
///   - remove items
///   - reset everything
///   - replace the whole content
///   - listen when anything changes
///
/// No UI Example:
/// ```dart
/// final users = AppListReactivityImpl<String>([]);
///
/// users.addListener(() {
///   print("Users updated: ${users.value}");
/// });
///
/// users.add("Alice");
/// // Output: Users updated: [Alice]
///
/// users.add("Bob");
/// // Output: Users updated: [Alice, Bob]
///
/// users.remove("Alice");
/// // Output: Users updated: [Bob]
///
/// users.clear();
/// // Output: Users updated: []
///
/// users.dispose(); // when done
/// ```
///
/// Dispose ownership:
/// As with [AppReactivity], the owner (typically a ViewModel)
/// is responsible for calling dispose.
abstract class AppListReactivity<T>
    implements AppObservableReactivity<List<T>> {
  /// Adds an item to the list.
  ///
  /// MUST:
  /// - produce a new list state
  /// - notify listeners synchronously if the list changes
  void add(T item);

  /// Replaces all items in the list with the given items.
  ///
  /// MUST:
  /// - produce a new list state
  /// - notify listeners synchronously if the list changes
  void replaceAll(List<T> items);

  /// Removes an item from the list.
  ///
  /// MUST:
  /// - produce a new list state
  /// - notify listeners synchronously if the list changes
  void remove(T item);

  /// Removes all items from the list.
  ///
  /// MUST:
  /// - produce a new list state that is empty
  /// - notify listeners if the list was not already empty
  void clear();
}
