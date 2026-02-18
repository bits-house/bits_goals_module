import 'package:bits_goals_module/src/core/presentation/state_management/view_model/impl/app_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestViewModel extends AppViewModel<int, String> {
  _TestViewModel({required super.initialState});

  void updateState(int newState) => setState(newState);

  void triggerEffect(String effect) => emitEffect(effect);
}

Future<void> _flushMicrotasks() => pumpEventQueue();

void main() {
  group('AppViewModel |', () {
    test('exposes the initial state provided in the constructor', () {
      final vm = _TestViewModel(initialState: 10);
      expect(vm.state, 10);
      vm.dispose();
    });

    group('State listeners |', () {
      test('notifies a listener when state changes', () {
        final vm = _TestViewModel(initialState: 0);
        int callCount = 0;
        int? lastObservedState;

        vm.addStateListener(() {
          callCount++;
          lastObservedState = vm.state;
        });

        vm.updateState(1);

        expect(callCount, 1);
        expect(lastObservedState, 1);
        vm.dispose();
      });

      test('does not notify if state is set to an equal value (idempotency)',
          () {
        final vm = _TestViewModel(initialState: 10);
        int callCount = 0;

        vm.addStateListener(() => callCount++);

        vm.updateState(10);

        expect(callCount, 0,
            reason: 'Listener must not be called if state did not change.');
        vm.dispose();
      });

      test('does not register the same listener twice', () {
        final vm = _TestViewModel(initialState: 0);
        int callCount = 0;
        void listener() => callCount++;

        vm.addStateListener(listener);
        vm.addStateListener(listener);

        vm.updateState(1);

        expect(callCount, 1,
            reason: 'The same listener instance must be registered only once.');
        vm.dispose();
      });

      test('stops notifying after removing a listener', () {
        final vm = _TestViewModel(initialState: 0);
        int callCount = 0;
        void listener() => callCount++;

        vm.addStateListener(listener);
        vm.updateState(1);
        expect(callCount, 1);

        vm.removeStateListener(listener);
        vm.updateState(2);
        expect(callCount, 1,
            reason: 'Listener must not be called after removal.');
        vm.dispose();
      });

      test('removing an unregistered listener does not throw', () {
        final vm = _TestViewModel(initialState: 0);
        void listener() {}

        expect(() => vm.removeStateListener(listener), returnsNormally);
        vm.dispose();
      });
    });

    group('Effects |', () {
      test('emits effects to a single subscriber', () async {
        final vm = _TestViewModel(initialState: 0);
        final received = <String>[];

        final sub = vm.effects.listen(received.add);

        vm.triggerEffect('A');
        vm.triggerEffect('B');
        await _flushMicrotasks();

        expect(received, ['A', 'B']);
        await sub.cancel();
        vm.dispose();
      });

      test(
          'effects stream is broadcast (multiple listeners receive the same event)',
          () async {
        final vm = _TestViewModel(initialState: 0);
        final receivedA = <String>[];
        final receivedB = <String>[];

        final subA = vm.effects.listen(receivedA.add);
        final subB = vm.effects.listen(receivedB.add);

        vm.triggerEffect('X');
        await _flushMicrotasks();

        expect(receivedA, ['X']);
        expect(receivedB, ['X']);

        await subA.cancel();
        await subB.cancel();
        vm.dispose();
      });

      test('cancelling one subscription does not affect other listeners',
          () async {
        final vm = _TestViewModel(initialState: 0);
        final receivedA = <String>[];
        final receivedB = <String>[];

        final subA = vm.effects.listen(receivedA.add);
        final subB = vm.effects.listen(receivedB.add);

        await subA.cancel();

        vm.triggerEffect('Y');
        await _flushMicrotasks();

        expect(receivedA, isEmpty);
        expect(receivedB, ['Y']);

        await subB.cancel();
        vm.dispose();
      });
    });

    group('Lifecycle (dispose) |', () {
      test('closes the effects stream on dispose', () async {
        final vm = _TestViewModel(initialState: 0);
        bool doneCalled = false;

        final sub = vm.effects.listen(
          (_) {},
          onDone: () {
            doneCalled = true;
          },
        );

        vm.dispose();
        await _flushMicrotasks();

        expect(doneCalled, isTrue,
            reason: 'Effects stream must complete after dispose.');
        await sub.cancel();
      });

      test('does not emit effects after dispose (and does not throw)',
          () async {
        final vm = _TestViewModel(initialState: 0);
        final received = <String>[];

        final sub = vm.effects.listen(received.add);

        vm.dispose();
        expect(() => vm.triggerEffect('after-dispose'), returnsNormally);
        await _flushMicrotasks();

        expect(received, isEmpty,
            reason: 'No effects must be emitted after dispose.');
        await sub.cancel();
      });

      test('ignores state updates after dispose', () {
        final vm = _TestViewModel(initialState: 0);
        int callCount = 0;

        vm.addStateListener(() => callCount++);

        vm.dispose();
        vm.updateState(123);

        expect(vm.state, 0, reason: 'State must not change after dispose.');
        expect(callCount, 0,
            reason: 'No listener notifications must happen after dispose.');
      });

      test('ignores adding new state listeners after dispose', () {
        final vm = _TestViewModel(initialState: 0);
        vm.dispose();

        int callCount = 0;
        vm.addStateListener(() => callCount++);

        vm.updateState(1);
        expect(callCount, 0,
            reason: 'Listeners added after dispose must be ignored.');
      });

      test('new effects subscription completes immediately after dispose',
          () async {
        final vm = _TestViewModel(initialState: 0);
        vm.dispose();

        bool doneCalled = false;
        final sub = vm.effects.listen(
          (_) {},
          onDone: () {
            doneCalled = true;
          },
        );

        await _flushMicrotasks();
        expect(doneCalled, isTrue);
        await sub.cancel();
      });
    });
  });
}
