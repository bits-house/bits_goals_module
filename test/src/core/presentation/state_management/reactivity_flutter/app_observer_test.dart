import 'dart:async';

import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_flutter/app_observer.dart';
import 'package:bits_goals_module/src/core/presentation/state_management/view_model/impl/app_view_model.dart';
import 'package:bits_goals_module/src/core/presentation/state_management/view_model/view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _SpyAppViewModel extends AppViewModel<int, String> {
  int disposeCallCount = 0;

  _SpyAppViewModel({required super.initialState});

  void updateState(int newState) => setState(newState);

  void emit(String effect) => emitEffect(effect);

  @override
  void dispose() {
    disposeCallCount++;
    super.dispose();
  }
}

/// A manual ViewModel (not based on AppObservable) to force edge cases
/// that are otherwise unreachable due to idempotency in AppObservable.
class _ManualViewModel implements ViewModel<int, String> {
  int _state;
  final _listeners = <VoidCallback>{};
  final _effectsController = StreamController<String>.broadcast();
  bool _disposed = false;

  _ManualViewModel(this._state);

  @override
  int get state => _state;

  @override
  Stream<String> get effects => _effectsController.stream;

  @override
  void addStateListener(VoidCallback listener) {
    if (_disposed) return;
    _listeners.add(listener);
  }

  @override
  void removeStateListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void updateState(
    int newState, {
    bool notifyEvenIfEqual = false,
  }) {
    if (_disposed) return;
    final oldState = _state;
    _state = newState;
    if (notifyEvenIfEqual || newState != oldState) {
      for (final l in _listeners.toList(growable: false)) {
        l();
      }
    }
  }

  void emit(String effect) {
    if (_disposed) return;
    _effectsController.add(effect);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _listeners.clear();
    _effectsController.close();
  }
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  group('AppObserver |', () {
    testWidgets('builds with the initial ViewModel state', (tester) async {
      final vm = _SpyAppViewModel(initialState: 10);
      int buildCount = 0;

      await tester.pumpWidget(
        _wrap(
          AppObserver<_SpyAppViewModel, int, String>(
            viewModel: vm,
            builder: (context, state) {
              buildCount++;
              return Text('state:$state', textDirection: TextDirection.ltr);
            },
          ),
        ),
      );

      expect(find.text('state:10'), findsOneWidget);
      expect(buildCount, 1);
    });

    testWidgets('rebuilds only when state changes', (tester) async {
      final vm = _SpyAppViewModel(initialState: 0);
      int buildCount = 0;

      await tester.pumpWidget(
        _wrap(
          AppObserver<_SpyAppViewModel, int, String>(
            viewModel: vm,
            builder: (context, state) {
              buildCount++;
              return Text('state:$state', textDirection: TextDirection.ltr);
            },
          ),
        ),
      );

      expect(buildCount, 1);
      vm.updateState(1);
      await tester.pump();
      expect(find.text('state:1'), findsOneWidget);
      expect(buildCount, 2);

      // Setting an equal value should not trigger a rebuild due to AppObservable idempotency.
      vm.updateState(1);
      await tester.pump();
      expect(buildCount, 2);
    });

    testWidgets(
        'does not call setState when notified but state is equal to cached value',
        (tester) async {
      final vm = _ManualViewModel(7);
      int buildCount = 0;

      await tester.pumpWidget(
        _wrap(
          AppObserver<_ManualViewModel, int, String>(
            viewModel: vm,
            builder: (context, state) {
              buildCount++;
              return Text('state:$state', textDirection: TextDirection.ltr);
            },
          ),
        ),
      );

      expect(buildCount, 1);
      // Force a state listener notification without a state change.
      vm.updateState(7, notifyEvenIfEqual: true);
      await tester.pump();
      expect(buildCount, 1,
          reason:
              'AppObserver must not rebuild if newState equals _currentState.');
    });

    testWidgets('calls onEffect without rebuilding the widget tree',
        (tester) async {
      final vm = _SpyAppViewModel(initialState: 0);
      int buildCount = 0;
      final effects = <String>[];

      await tester.pumpWidget(
        _wrap(
          AppObserver<_SpyAppViewModel, int, String>(
            viewModel: vm,
            builder: (context, state) {
              buildCount++;
              return Text('state:$state', textDirection: TextDirection.ltr);
            },
            onEffect: (context, effect) {
              effects.add(effect);
            },
          ),
        ),
      );

      expect(buildCount, 1);
      vm.emit('E1');
      await tester.pump();
      expect(effects, ['E1']);
      expect(buildCount, 1, reason: 'Effects must not trigger rebuilds.');
    });

    testWidgets('handles emitted effects when onEffect is null',
        (tester) async {
      final vm = _SpyAppViewModel(initialState: 0);
      int buildCount = 0;

      await tester.pumpWidget(
        _wrap(
          AppObserver<_SpyAppViewModel, int, String>(
            viewModel: vm,
            builder: (context, state) {
              buildCount++;
              return Text('state:$state', textDirection: TextDirection.ltr);
            },
            onEffect: null,
          ),
        ),
      );

      vm.emit('IGNORED');
      await tester.pump();
      expect(buildCount, 1,
          reason: 'Effects must not rebuild even without onEffect.');
    });

    testWidgets('disposes the ViewModel when removed (default behavior)',
        (tester) async {
      final vm = _SpyAppViewModel(initialState: 0);

      await tester.pumpWidget(
        _wrap(
          AppObserver<_SpyAppViewModel, int, String>(
            viewModel: vm,
            builder: (context, state) {
              return Text('state:$state', textDirection: TextDirection.ltr);
            },
          ),
        ),
      );

      expect(vm.disposeCallCount, 0);

      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
      await tester.pump();

      expect(vm.disposeCallCount, 1);
    });

    testWidgets(
        'switches listeners when the ViewModel instance changes and disposes the old one (when enabled)',
        (tester) async {
      final oldVm = _SpyAppViewModel(initialState: 1);
      final newVm = _SpyAppViewModel(initialState: 100);
      int buildCount = 0;

      Widget make(_SpyAppViewModel vm) {
        return _wrap(
          AppObserver<_SpyAppViewModel, int, String>(
            viewModel: vm,
            builder: (context, state) {
              buildCount++;
              return Text('state:$state $buildCount',
                  textDirection: TextDirection.ltr);
            },
          ),
        );
      }

      await tester.pumpWidget(make(oldVm));
      expect(find.text('state:1 1'), findsOneWidget);

      await tester.pumpWidget(make(newVm));
      await tester.pump();

      expect(oldVm.disposeCallCount, 1,
          reason: 'Old ViewModel must be disposed on swap.');
      expect(find.text('state:100 2'), findsOneWidget);

      // Updates in the old VM must not affect UI anymore.
      oldVm.updateState(2);
      await tester.pump();
      expect(find.text('state:100 2'), findsOneWidget);

      // Updates in the new VM must affect UI.
      newVm.updateState(101);
      await tester.pump();
      expect(find.text('state:101 3'), findsOneWidget);
    });

    testWidgets('does nothing in didUpdateWidget when ViewModel is unchanged',
        (tester) async {
      final vm = _SpyAppViewModel(initialState: 1);
      int buildCount = 0;

      Widget make() {
        return _wrap(
          AppObserver<_SpyAppViewModel, int, String>(
            viewModel: vm,
            builder: (context, state) {
              buildCount++;
              return Text('state:$state', textDirection: TextDirection.ltr);
            },
          ),
        );
      }

      await tester.pumpWidget(make());
      await tester.pumpWidget(make());
      await tester.pump();

      expect(vm.disposeCallCount, 0,
          reason: 'VM must not be disposed if it did not change.');
      expect(buildCount, greaterThanOrEqualTo(1));
      vm.dispose();
    });
  });
}
