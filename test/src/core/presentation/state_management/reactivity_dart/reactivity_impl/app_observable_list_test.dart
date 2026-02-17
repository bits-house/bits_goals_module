import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_dart/reactivity_impl/app_observable_list.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppObservableList |', () {
    group('Initialization |', () {
      test(
          'should start with an empty list if no argument is provided (or an empty list)',
          () {
        final list = AppObservableList<int>([]);
        expect(list.value, isEmpty);
        expect(list.value, isA<List<int>>());
      });

      test('should start with the values passed to the constructor', () {
        final list = AppObservableList<String>(['A', 'B']);
        expect(list.value, hasLength(2));
        expect(list.value, containsAll(['A', 'B']));
      });
    });

    group('Mutations and Reactivity |', () {
      late AppObservableList<int> list;

      setUp(() {
        list = AppObservableList<int>([]);
      });

      test('add() should add an item and notify listeners', () {
        int callCount = 0;
        list.addListener(() => callCount++);

        list.add(1);

        expect(list.value, [1]);
        expect(callCount, 1,
            reason: "Listener must be called when adding an item");
      });

      test('remove() should remove an item and notify listeners', () {
        list.add(10);
        list.add(20);

        int callCount = 0;
        list.addListener(
            () => callCount++); // Registers listener after initial setup

        list.remove(10);

        expect(list.value, [20]);
        expect(callCount, 1,
            reason: "Listener must be called when removing an item");
      });

      test('remove() for a non-existent item should not break', () {
        list.add(1);

        int callCount = 0;
        list.addListener(() => callCount++);

        list.remove(999); // Item does not exist
        list.remove(999); // Item does not exist

        expect(list.value, [1]);
        expect(callCount, 0,
            reason:
                "Must not notify if the list did not undergo a structural change");
      });

      test('clear() should clear the list and notify', () {
        list.add(1);
        list.add(2);

        int callCount = 0;
        list.addListener(() => callCount++);

        list.clear();

        expect(list.value, isEmpty);
        expect(callCount, 1);
      });

      test('replaceAll() should replace all contents and notify', () {
        list.add(1);

        int callCount = 0;
        list.addListener(() => callCount++);

        list.replaceAll([10, 20]);

        expect(list.value, [10, 20]);
        expect(callCount, 1);
      });
    });

    group('Setter Behavior (value =) |', () {
      test(
          'setter should replace contents (clear + addAll) while keeping the reactive instance',
          () {
        final list = AppObservableList<String>(['Initial']);

        int callCount = 0;
        list.addListener(() => callCount++);

        // The setter implementation does ..clear()..addAll()
        // This is a bulk mutation.
        list.value = ['New'];

        expect(list.value, ['New']);
        expect(callCount, 1);
      });

      test('setter should NOT break existing listeners', () {
        // If the setter replaced the instance (_observableList = newValue),
        // listeners attached to the old instance would stop working.
        // This test ensures the implementation is correct (mutating in-place).
        final list = AppObservableList<int>([1]);

        bool notified = false;
        list.addListener(() => notified = true);

        list.value = [2];

        expect(notified, isTrue,
            reason: "Listeners must persist after setting value");
      });
    });

    group('Listener Management |', () {
      test('should support multiple independent listeners', () {
        final list = AppObservableList<int>([]);
        int c1 = 0;
        int c2 = 0;

        list.addListener(() => c1++);
        list.addListener(() => c2++);

        list.add(1);

        expect(c1, 1);
        expect(c2, 1);
      });

      test(
          'removeListener should stop notifications for that specific listener',
          () {
        final list = AppObservableList<int>([]);
        int c1 = 0;
        void l1() => c1++;

        list.addListener(l1);
        list.add(1); // c1 = 1

        list.removeListener(l1);
        list.add(2); // c1 must remain 1

        expect(c1, 1);
        expect(list.value, [1, 2]);
      });

      test('should not add the same listener twice', () {
        final list = AppObservableList<int>([]);
        int calls = 0;
        void l() => calls++;

        list.addListener(l);
        list.addListener(l);

        list.add(1);
        expect(calls, 1);
      });
    });

    group('Lifecycle (Dispose) |', () {
      test('dispose should prevent subsequent modifications (add/remove/set)',
          () {
        final list = AppObservableList<int>([1]);
        list.dispose();

        // Tries to modify
        list.add(2);
        list.remove(1);
        list.clear();
        list.value = [99];
        list.replaceAll([100]);

        // Verifies nothing changed
        // Note: The implementation uses "if (_disposed) return;" in all methods.
        // If the underlying list isn't touched, it remains [1].
        expect(list.value, [1], reason: "State must freeze after dispose");
      });

      test('dispose should remove all listeners and clean up resources', () {
        final list = AppObservableList<int>([]);
        bool called = false;

        list.addListener(() => called = true);

        list.dispose();

        // Tries to force a reaction (even though mutation methods are blocked,
        // we ensure the listener was disconnected).
        // Accesses the internal list directly via the getter and mutates it (bypassing wrapper protection)
        // to prove the listener (reaction) was disposed.

        // *Technical note*: The getter returns the _observableList. If we modify it directly
        // outside the wrapper class, and the disposer had not been called, the listener would fire.
        list.value.add(10);

        expect(called, isFalse,
            reason:
                "No listener must be called after dispose, even with direct modification of the internal list");
      });

      test('calling dispose multiple times is safe', () {
        final list = AppObservableList<int>([]);
        list.dispose();
        expect(() => list.dispose(), returnsNormally);
      });
    });

    group('Integration with Complex Types |', () {
      test('should work with a list of objects', () {
        final list = AppObservableList<_Item>([]);
        final item1 = _Item(id: 1, name: 'A');

        list.add(item1);
        expect(list.value.first.name, 'A');

        list.remove(item1);
        expect(list.value, isEmpty);
      });
    });
  });
}

class _Item {
  final int id;
  final String name;
  _Item({required this.id, required this.name});
}
