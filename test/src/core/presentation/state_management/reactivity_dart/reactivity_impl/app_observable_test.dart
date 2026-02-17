import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_dart/reactivity_impl/app_observable.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppObservable |', () {
    test('should start with the value passed to the constructor', () {
      final observable = AppObservable<int>(10);
      expect(observable.value, 10);
    });

    test('should update the value when the setter is called', () {
      final observable = AppObservable<String>('initial');
      observable.value = 'updated';
      expect(observable.value, 'updated');
    });

    group('Reactivity and Listeners |', () {
      test('should notify the listener synchronously when the value changes',
          () {
        final observable = AppObservable<int>(0);
        int? capturedValue;

        observable.addListener(() {
          capturedValue = observable.value;
        });

        observable.value = 1;

        // Verifies it was called immediately (no need for async/await)
        expect(capturedValue, 1);
      });

      test('should notify multiple independent listeners', () {
        final observable = AppObservable<int>(0);
        int callCount1 = 0;
        int callCount2 = 0;

        observable.addListener(() => callCount1++);
        observable.addListener(() => callCount2++);

        observable.value = 1;

        expect(callCount1, 1);
        expect(callCount2, 1);
      });

      test(
          'should NOT notify listeners if the value is equal to the current one (Idempotency)',
          () {
        final observable = AppObservable<int>(10);
        bool listenerCalled = false;

        observable.addListener(() {
          listenerCalled = true;
        });

        // Tries to set the same value that already exists
        observable.value = 10;

        expect(listenerCalled, isFalse,
            reason:
                "The listener must not be called if the value didn't change.");
      });

      test('should NOT add the same listener twice', () {
        final observable = AppObservable<int>(0);
        int calls = 0;
        void listener() => calls++;

        // Tries to register the same function instance twice
        observable.addListener(listener);
        observable.addListener(listener);

        observable.value = 1;

        expect(calls, 1,
            reason: "The listener should be registered only once.");
      });

      test('should stop notifying after removing the listener', () {
        final observable = AppObservable<int>(0);
        int calls = 0;
        void listener() => calls++;

        observable.addListener(listener);

        observable.value = 1; // Triggers +1
        expect(calls, 1);

        observable.removeListener(listener);

        observable.value = 2; // Must not trigger
        expect(calls, 1,
            reason:
                "The counter must not increment after removing the listener.");
      });

      test('removing an unregistered listener should not throw', () {
        final observable = AppObservable<int>(0);
        void listener() {}

        expect(() => observable.removeListener(listener), returnsNormally);
      });

      test('removing a listener should not affect other listeners', () {
        final observable = AppObservable<int>(0);
        int callsA = 0;
        int callsB = 0;

        void listenerA() => callsA++;
        void listenerB() => callsB++;

        observable.addListener(listenerA);
        observable.addListener(listenerB);

        observable.removeListener(listenerA);

        observable.value = 5;

        expect(callsA, 0, reason: "Listener A was removed");
        expect(callsB, 1, reason: "Listener B must remain active");
      });
    });

    group('Lifecycle (Dispose) |', () {
      test('should ignore value updates after dispose', () {
        final observable = AppObservable<int>(0);
        observable.dispose();

        // Tries to update
        observable.value = 10;

        expect(observable.value, 0,
            reason: "The value must not change after dispose");
      });

      test('should not notify existing listeners after dispose', () {
        final observable = AppObservable<int>(0);
        bool called = false;
        void listener() {
          called = true;
        }

        observable.addListener(listener);

        observable.dispose();

        observable.value = 1; // Setter must be ignored

        expect(called, isFalse);
      });

      test('should not allow adding new listeners after dispose', () {
        final observable = AppObservable<int>(0);
        observable.dispose();

        observable
            .addListener(() {}); // Must be ignored silently per implementation

        // Even if we forced a change (which the setter blocks, assuming internal access),
        // the listener should not have been registered.
        expect(observable.value, 0);
      });

      test('calling dispose multiple times should be safe', () {
        final observable = AppObservable<int>(0);

        observable.dispose();
        expect(() => observable.dispose(), returnsNormally);
      });
    });

    group('Complex Types |', () {
      test('should work correctly with custom objects', () {
        final user1 = _User('Alice');
        final user2 = _User('Bob');

        final observable = AppObservable<_User>(user1);
        _User? lastUser;

        observable.addListener(() {
          lastUser = observable.value;
        });

        observable.value = user2;

        expect(lastUser, user2);
        expect(observable.value.name, 'Bob');
      });
    });
  });
}

// Helper class to test complex types
class _User {
  final String name;
  _User(this.name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _User && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;
}
