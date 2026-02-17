import 'dart:async';

import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_dart/reactivity_impl/app_observable.dart';
import 'package:bits_goals_module/src/core/presentation/state_management/view_model/impl/app_streamed_list_view_model.dart';
import 'package:bits_goals_module/src/core/presentation/state_management/view_model/view_model.dart';
import 'package:flutter/foundation.dart';

/// A base ViewModel implementation that MUST be extended by every ViewModel in the app that
/// does not fit in the specialized ones (e.g., [AppStreamedListViewModel]).
abstract class AppViewModel<S, E> implements ViewModel<S, E> {
  late final AppObservable<S> _state;
  final _effectController = StreamController<E>.broadcast();

  AppViewModel(S initialState) {
    _state = AppObservable<S>(initialState);
  }

  @override
  S get state => _state.value;

  @override
  void addStateListener(VoidCallback listener) {
    _state.addListener(listener);
  }

  @override
  void removeStateListener(VoidCallback listener) {
    _state.removeListener(listener);
  }

  @override
  Stream<E> get effects => _effectController.stream;

  @override
  @mustCallSuper
  void dispose() {
    _state.dispose();
    _effectController.close();
  }

  @protected
  void setState(S newState) {
    _state.value = newState;
  }

  @protected
  void emitEffect(E effect) {
    if (!_effectController.isClosed) {
      _effectController.add(effect);
    }
  }
}
