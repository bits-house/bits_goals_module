import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_dart/app_observable_reactivity.dart';
import 'package:mobx/mobx.dart';

class AppObservable<T> implements AppObservableReactivity<T> {
  final Observable<T> _observable;
  final _listeners = <void Function(), ReactionDisposer>{};
  bool _disposed = false;

  AppObservable(T initial) : _observable = Observable(initial);

  @override
  T get value => _observable.value;

  @override
  set value(T v) {
    if (_disposed) return;
    if (_observable.value == v) return;
    runInAction(() {
      _observable.value = v;
    });
  }

  @override
  void addListener(void Function() listener) {
    if (_disposed) return;
    if (_listeners.containsKey(listener)) return;
    final disposer = reaction<T>(
      (_) => _observable.value,
      (_) => listener(),
      fireImmediately: false,
    );
    _listeners[listener] = disposer;
  }

  @override
  void removeListener(void Function() listener) {
    final disposer = _listeners.remove(listener);
    disposer?.call();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final d in _listeners.values) {
      d();
    }
    _listeners.clear();
  }
}
