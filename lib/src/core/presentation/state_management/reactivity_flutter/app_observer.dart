import 'dart:async';
import 'package:bits_goals_module/src/core/presentation/state_management/view_model/view_model.dart';
import 'package:flutter/material.dart';

/// A universal wrapper widget that connects a [ViewModel] to the UI.
///
/// Responsibilities:
/// 1. Rebuilds the UI *only* when state [S] changes.
/// 2. Executes [onEffect] when an effect is emitted, *without* rebuilding the UI.
///
/// NOT responsibilities:
/// 1. Rebuild the UI for other reactive properties of the ViewModel other than state [S] (if any).
class AppObserver<VM extends ViewModel<S, E>, S, E> extends StatefulWidget {
  /// The ViewModel instance that holds the state and effects for this widget.
  final VM viewModel;

  /// Set to false if the ViewModel is shared across multiple widgets or has a longer
  /// lifecycle than this widget (singleton).
  /// It is defaulted to true, the ViewModel will be disposed when this widget is removed from
  /// the tree (factory).
  final bool shouldDisposeViewModel;

  /// Function responsible for drawing the screen based on the current state [S].
  final Widget Function(BuildContext context, S state) builder;

  /// Optional function to handle side effects [E] (navigation, snackbars).
  /// This callback is executed without triggering a widget rebuild.
  final void Function(BuildContext context, E effect)? onEffect;

  const AppObserver({
    super.key,
    required this.viewModel,
    required this.builder,
    this.shouldDisposeViewModel = true,
    this.onEffect,
  });

  @override
  State<AppObserver<VM, S, E>> createState() => _AppObserverState<VM, S, E>();
}

class _AppObserverState<VM extends ViewModel<S, E>, S, E>
    extends State<AppObserver<VM, S, E>> {
  late S _currentState;
  StreamSubscription<E>? _effectSubscription;

  @override
  void initState() {
    super.initState();
    // 1. Initialize local state with the current VM value
    _currentState = widget.viewModel.state;

    // 2. Setup listeners
    _subscribeToEffects();
    widget.viewModel.addStateListener(_onStateChanged);
  }

  /// Handles Hot Reloads or Parent Rebuilds.
  /// If the [widget.viewModel] instance changes, we must switch listeners to the new one.
  @override
  void didUpdateWidget(covariant AppObserver<VM, S, E> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      // 1. Clean up old listeners
      _effectSubscription?.cancel();
      oldWidget.viewModel.removeStateListener(_onStateChanged);

      // 2. Dispose OLD ViewModel in case [shouldDisposeViewModel] is true, if the ViewModel changed,
      // we assume the old one is no longer needed and should be disposed to free resources.
      if (oldWidget.shouldDisposeViewModel) {
        oldWidget.viewModel.dispose();
      }

      // 3. Subscribe to the new ViewModel
      _currentState = widget.viewModel.state;
      _subscribeToEffects();
      widget.viewModel.addStateListener(_onStateChanged);
    }
  }

  void _subscribeToEffects() {
    _effectSubscription = widget.viewModel.effects.listen(
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
    final newState = widget.viewModel.state;
    if (newState != _currentState) {
      setState(() {
        _currentState = newState;
      });
    }
  }

  @override
  void dispose() {
    _effectSubscription?.cancel();
    widget.viewModel.removeStateListener(_onStateChanged);
    if (widget.shouldDisposeViewModel) {
      widget.viewModel.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _currentState);
  }
}
