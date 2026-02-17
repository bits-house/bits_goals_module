import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_dart/app_list_reactivity.dart';
import 'package:mobx/mobx.dart';

class AppObservableList<T> implements AppListReactivity<T> {
  final ObservableList<T> _observableList;
  final _listeners = <void Function(), ReactionDisposer>{};
  bool _disposed = false;

  AppObservableList(List<T> initial)
      : _observableList = ObservableList.of(initial);

  @override
  List<T> get value => _observableList;

  @override
  set value(List<T> newValue) {
    if (_disposed) return;

    runInAction(() {
      _observableList
        ..clear()
        ..addAll(newValue);
    });
  }

  @override
  void add(T item) {
    if (_disposed) return;
    runInAction(() => _observableList.add(item));
  }

  @override
  void replaceAll(List<T> items) {
    if (_disposed) return;
    runInAction(() {
      _observableList
        ..clear()
        ..addAll(items);
    });
  }

  @override
  void remove(T item) {
    if (_disposed) return;
    runInAction(() => _observableList.remove(item));
  }

  @override
  void clear() {
    if (_disposed) return;
    runInAction(_observableList.clear);
  }

  @override
  void addListener(void Function() listener) {
    if (_disposed) return;
    if (_listeners.containsKey(listener)) return;

    final disposer = reaction<List<T>>(
      (_) => _observableList.toList(),
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
