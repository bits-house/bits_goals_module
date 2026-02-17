import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_dart/app_reactivity.dart';
import 'package:mobx/mobx.dart';

class AppComputed<T> implements AppReactivity<T> {
  late final Computed<T> _computed;
  final _listeners = <void Function(), ReactionDisposer>{};
  bool _disposed = false;

  AppComputed(T Function() calculator) {
    _computed = Computed(calculator);
  }

  @override
  T get value => _computed.value;

  @override
  void addListener(void Function() listener) {
    if (_disposed) return;
    if (_listeners.containsKey(listener)) return;
    final disposer = reaction<T>(
      (_) => _computed.value,
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
