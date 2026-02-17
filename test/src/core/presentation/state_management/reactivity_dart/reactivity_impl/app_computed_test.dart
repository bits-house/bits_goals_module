import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_dart/reactivity_impl/app_computed.dart';
import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_dart/reactivity_impl/app_observable.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppComputed |', () {
    late AppObservable<int> count;
    late AppComputed<String> computedText;

    setUp(() {
      count = AppObservable(0);
      // Creates a computed that depends on 'count'
      computedText = AppComputed(() => 'Count is ${count.value}');
    });

    tearDown(() {
      count.dispose();
      computedText.dispose();
    });

    test('should return the initial computed value correctly', () {
      expect(computedText.value, 'Count is 0');
    });

    test('should update the value when a dependency changes', () {
      count.value = 1;
      expect(computedText.value, 'Count is 1');
    });

    group('Listeners and Notifications |', () {
      test('should notify listeners when the computed result changes', () {
        bool called = false;
        computedText.addListener(() => called = true);

        count.value = 5;

        expect(called, isTrue);
        expect(computedText.value, 'Count is 5');
      });

      test(
          'should NOT notify listeners if the computed result is the same (Filtering/Distinct)',
          () {
        // Scenario: boolean computed "is even?"
        final isEven = AppComputed<bool>(() => count.value % 2 == 0);

        int notifications = 0;
        isEven.addListener(() => notifications++);

        // Initial value is 0 (Even -> true)
        expect(isEven.value, isTrue);

        // Changes to 2 (Even -> true). The base value changed, but the result did NOT.
        count.value = 2;

        expect(notifications, 0,
            reason:
                "Must not notify because 'true' -> 'true' is not a state change.");

        // Changes to 3 (Odd -> false). The result changed.
        count.value = 3;
        expect(notifications, 1,
            reason: "Must notify because it changed from true to false.");

        isEven.dispose();
      });

      test('should allow multiple listeners', () {
        int c1 = 0;
        int c2 = 0;

        computedText.addListener(() => c1++);
        computedText.addListener(() => c2++);

        count.value = 10;

        expect(c1, 1);
        expect(c2, 1);
      });

      test('removeListener should stop notifications', () {
        int calls = 0;
        void listener() => calls++;

        computedText.addListener(listener);
        count.value = 1;
        expect(calls, 1);

        computedText.removeListener(listener);
        count.value = 2;
        expect(calls, 1,
            reason: "Listener was removed and must not receive new updates.");
      });
    });

    group('Multiple Dependencies |', () {
      test('should react to changes in any dependency', () {
        final firstName = AppObservable('João');
        final lastName = AppObservable('Silva');

        final fullName =
            AppComputed(() => '${firstName.value} ${lastName.value}');

        expect(fullName.value, 'João Silva');

        // Changes first dependency
        firstName.value = 'Maria';
        expect(fullName.value, 'Maria Silva');

        // Changes second dependency
        lastName.value = 'Souza';
        expect(fullName.value, 'Maria Souza');

        firstName.dispose();
        lastName.dispose();
        fullName.dispose();
      });
    });

    group('Lifecycle (Dispose) |', () {
      test('should not allow adding listeners after dispose', () {
        computedText.dispose();

        bool called = false;
        computedText.addListener(() => called = true);

        // Forces a dependency update
        // Even if the dependency changes, the computed is "dead" for external listeners
        count.value = 99;

        expect(called, isFalse);
      });

      test('dispose should clear internal listeners and prevent leaks', () {
        bool called = false;
        computedText.addListener(() => called = true);

        computedText.dispose();

        count.value = 100;

        expect(called, isFalse,
            reason: "No listener must be called after dispose");
      });

      test('calling dispose multiple times should not throw', () {
        computedText.dispose();
        expect(() => computedText.dispose(), returnsNormally);
      });
    });

    group('Robustness |', () {
      test('should handle duplicate listeners (addListener idempotency)', () {
        int calls = 0;
        void listener() => calls++;

        computedText.addListener(listener);
        computedText.addListener(listener); // Adds the same

        count.value = 1;

        expect(calls, 1, reason: "Must register the listener only once");
      });
    });
  });
}
