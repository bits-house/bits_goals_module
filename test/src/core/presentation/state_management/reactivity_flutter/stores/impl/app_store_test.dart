import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_flutter/stores/impl/app_store.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestStore extends AppStore<int, String> {
  _TestStore({required super.initialState});

  void updateState(int newState) => setState(newState);

  void triggerEffect(String effect) => emitEffect(effect);
}

Future<void> _flushMicrotasks() => pumpEventQueue();

void main() {
  group('AppStore |', () {
    test('exposes the initial state provided in the constructor', () {
      final st = _TestStore(initialState: 10);
      expect(st.state, 10);
      st.dispose();
    });

    group('State listeners |', () {
      test('notifies a listener when state changes', () {
        final st = _TestStore(initialState: 0);
        int callCount = 0;
        int? lastObservedState;

        st.addStateListener(() {
          callCount++;
          lastObservedState = st.state;
        });

        st.updateState(1);

        expect(callCount, 1);
        expect(lastObservedState, 1);
        st.dispose();
      });

      test('does not notify if state is set to an equal value (idempotency)',
          () {
        final st = _TestStore(initialState: 10);
        int callCount = 0;

        st.addStateListener(() => callCount++);

        st.updateState(10);

        expect(callCount, 0,
            reason: 'Listener must not be called if state did not change.');
        st.dispose();
      });

      test('does not register the same listener twice', () {
        final st = _TestStore(initialState: 0);
        int callCount = 0;
        void listener() => callCount++;

        st.addStateListener(listener);
        st.addStateListener(listener);

        st.updateState(1);

        expect(callCount, 1,
            reason: 'The same listener instance must be registered only once.');
        st.dispose();
      });

      test('stops notifying after removing a listener', () {
        final st = _TestStore(initialState: 0);
        int callCount = 0;
        void listener() => callCount++;

        st.addStateListener(listener);
        st.updateState(1);
        expect(callCount, 1);

        st.removeStateListener(listener);
        st.updateState(2);
        expect(callCount, 1,
            reason: 'Listener must not be called after removal.');
        st.dispose();
      });

      test('removing an unregistered listener does not throw', () {
        final st = _TestStore(initialState: 0);
        void listener() {}

        expect(() => st.removeStateListener(listener), returnsNormally);
        st.dispose();
      });
    });

    group('Effects |', () {
      test('emits effects to a single subscriber', () async {
        final st = _TestStore(initialState: 0);
        final received = <String>[];

        final sub = st.effects.listen(received.add);

        st.triggerEffect('A');
        st.triggerEffect('B');
        await _flushMicrotasks();

        expect(received, ['A', 'B']);
        await sub.cancel();
        st.dispose();
      });

      test(
          'effects stream is broadcast (multiple listeners receive the same event)',
          () async {
        final st = _TestStore(initialState: 0);
        final receivedA = <String>[];
        final receivedB = <String>[];

        final subA = st.effects.listen(receivedA.add);
        final subB = st.effects.listen(receivedB.add);

        st.triggerEffect('X');
        await _flushMicrotasks();

        expect(receivedA, ['X']);
        expect(receivedB, ['X']);

        await subA.cancel();
        await subB.cancel();
        st.dispose();
      });

      test('cancelling one subscription does not affect other listeners',
          () async {
        final st = _TestStore(initialState: 0);
        final receivedA = <String>[];
        final receivedB = <String>[];

        final subA = st.effects.listen(receivedA.add);
        final subB = st.effects.listen(receivedB.add);

        await subA.cancel();

        st.triggerEffect('Y');
        await _flushMicrotasks();

        expect(receivedA, isEmpty);
        expect(receivedB, ['Y']);

        await subB.cancel();
        st.dispose();
      });
    });

    group('Lifecycle (dispose) |', () {
      test('closes the effects stream on dispose', () async {
        final st = _TestStore(initialState: 0);
        bool doneCalled = false;

        final sub = st.effects.listen(
          (_) {},
          onDone: () {
            doneCalled = true;
          },
        );

        st.dispose();
        await _flushMicrotasks();

        expect(doneCalled, isTrue,
            reason: 'Effects stream must complete after dispose.');
        await sub.cancel();
      });

      test('does not emit effects after dispose (and does not throw)',
          () async {
        final st = _TestStore(initialState: 0);
        final received = <String>[];

        final sub = st.effects.listen(received.add);

        st.dispose();
        expect(() => st.triggerEffect('after-dispose'), returnsNormally);
        await _flushMicrotasks();

        expect(received, isEmpty,
            reason: 'No effects must be emitted after dispose.');
        await sub.cancel();
      });

      test('ignores state updates after dispose', () {
        final st = _TestStore(initialState: 0);
        int callCount = 0;

        st.addStateListener(() => callCount++);

        st.dispose();
        st.updateState(123);

        expect(st.state, 0, reason: 'State must not change after dispose.');
        expect(callCount, 0,
            reason: 'No listener notifications must happen after dispose.');
      });

      test('ignores adding new state listeners after dispose', () {
        final st = _TestStore(initialState: 0);
        st.dispose();

        int callCount = 0;
        st.addStateListener(() => callCount++);

        st.updateState(1);
        expect(callCount, 0,
            reason: 'Listeners added after dispose must be ignored.');
      });

      test('new effects subscription completes immediately after dispose',
          () async {
        final st = _TestStore(initialState: 0);
        st.dispose();

        bool doneCalled = false;
        final sub = st.effects.listen(
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
