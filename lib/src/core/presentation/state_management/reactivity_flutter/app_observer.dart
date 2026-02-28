import 'dart:async';
import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_flutter/app_provider.dart';
import 'package:bits_goals_module/src/core/presentation/state_management/app_stores/store.dart';
import 'package:flutter/material.dart';

/// A universal wrapper widget that connects a [Store] to the UI.
///
/// Responsibilities:
/// 1. Rebuilds the UI *only* when state [S] changes.
/// 2. Executes [onEffect] when an effect is emitted, *without* rebuilding the UI.
/// 3. Manages the lifecycle of the [Store], including disposing it when the widget
/// is removed from the tree.
/// 4. Provides the [Store] to the widget subtree via [AppProvider] inherited widget.
///
/// NOT responsibilities:
/// 1. Rebuild the UI for other reactive properties of the Store other than state [S] (if any).
class AppObserver<ST extends Store<S, E>, S, E> extends StatefulWidget {
  /// The Store instance that holds the state and effects for this widget.
  final ST store;

  /// Function responsible for drawing the screen based on the current state [S].
  final Widget Function(BuildContext context, S state) builder;

  /// Optional function to handle side effects [E] (navigation, snackbars).
  /// This callback is executed without triggering a widget rebuild.
  final void Function(BuildContext context, E effect)? onEffect;

  const AppObserver({
    super.key,
    required this.store,
    required this.builder,
    this.onEffect,
  });

  @override
  State<AppObserver<ST, S, E>> createState() => _AppObserverState<ST, S, E>();
}

class _AppObserverState<ST extends Store<S, E>, S, E>
    extends State<AppObserver<ST, S, E>> {
  late S _currentState;
  StreamSubscription<E>? _effectSubscription;

  @override
  void initState() {
    super.initState();
    // 1. Initialize local state with the current store value
    _currentState = widget.store.state;

    // 2. Setup listeners
    _subscribeToEffects();
    widget.store.addStateListener(_onStateChanged);
  }

  /// Handles Hot Reloads or Parent Rebuilds.
  /// If the [widget.store] instance changes, we must switch listeners to the new one.
  @override
  void didUpdateWidget(covariant AppObserver<ST, S, E> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store) {
      // 1. Clean up old listeners
      _effectSubscription?.cancel();
      oldWidget.store.removeStateListener(_onStateChanged);

      // 2. Dispose OLD Store, if the Store changed,
      oldWidget.store.dispose();

      // 3. Subscribe to the new Store
      _currentState = widget.store.state;
      _subscribeToEffects();
      widget.store.addStateListener(_onStateChanged);
    }
  }

  void _subscribeToEffects() {
    _effectSubscription = widget.store.effects.listen(
      (effect) {
        if (mounted) {
          if (widget.onEffect != null) {
            widget.onEffect!(context, effect);
          }
        }
      },
    );
  }

  void _onStateChanged() {
    if (!mounted) return;
    final newState = widget.store.state;
    if (newState != _currentState) {
      setState(() {
        _currentState = newState;
      });
    }
  }

  @override
  void dispose() {
    _effectSubscription?.cancel();
    widget.store.removeStateListener(_onStateChanged);
    widget.store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppProvider<ST>(
      store: widget.store,
      child: widget.builder(context, _currentState),
    );
  }
}
