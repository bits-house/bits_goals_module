import 'dart:async';

import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_dart/reactivity_impl/app_observable.dart';
import 'package:bits_goals_module/src/core/presentation/state_management/store/impl/app_streamed_list_store.dart';
import 'package:bits_goals_module/src/core/presentation/state_management/store/store.dart';
import 'package:flutter/foundation.dart';

// TODO: mitigar erros de concorrência e reentrância: Double Submit, Stale Completion,
//  Reentrância de State, etc.

/// A base Store implementation that MUST be extended by every Store in the app that
/// does not fit in the specialized ones (e.g., [AppStreamedListStore]).
abstract class AppStore<S, E> implements Store<S, E> {
  late final AppObservable<S> _state;
  final _effectController = StreamController<E>.broadcast();

  AppStore({required S initialState}) {
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
