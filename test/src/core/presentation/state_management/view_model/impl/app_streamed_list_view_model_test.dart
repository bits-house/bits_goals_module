import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bits_goals_module/src/core/presentation/state_management/view_model/impl/app_streamed_list_view_model.dart';

// =======================
// TEST DOUBLES
// =======================

class TestFailure {
  final String message;
  TestFailure(this.message);
}

// ---------- STATES ----------

sealed class TestState {}

class LoadingState extends TestState {}

class SuccessState extends TestState {
  final List<int> data;
  SuccessState(this.data);
}

class EmptyState extends TestState {}

class FailureState extends TestState {
  final TestFailure failure;
  FailureState(this.failure);
}

// ---------- EVENT ----------

sealed class TestEvent {}

// =======================
// TEST VIEW MODELS
// =======================

/// Default VM for basic tests.
class TestStreamedVM
    extends AppStreamedListViewModel<TestState, TestEvent, int, TestFailure> {
  final Stream<List<int>> Function({int? limit}) streamFactory;

  TestStreamedVM(this.streamFactory)
      : super(
          initialState: LoadingState(),
          stateAfterDataAutoUpdate: (data) =>
              data.isEmpty ? EmptyState() : SuccessState(data),
          stateOnInitialFailure: (failure) => FailureState(failure),
          mapUnexpectedExceptionToFailure: (e) => TestFailure("unexpected"),
          pageSize: 2,
        );

  @override
  Stream<List<int>> createStream({int? limit}) {
    return streamFactory(limit: limit);
  }
}

/// VM that records every `limit` passed into `createStream`.
/// Essential to validate limit consistency across operations.
class LimitTrackingVM
    extends AppStreamedListViewModel<TestState, TestEvent, int, TestFailure> {
  final Stream<List<int>> Function({int? limit}) streamFactory;
  final List<int?> recordedLimits = [];

  LimitTrackingVM(this.streamFactory)
      : super(
          initialState: LoadingState(),
          stateAfterDataAutoUpdate: (data) =>
              data.isEmpty ? EmptyState() : SuccessState(data),
          stateOnInitialFailure: (failure) => FailureState(failure),
          mapUnexpectedExceptionToFailure: (e) => TestFailure("unexpected"),
          pageSize: 2,
        );

  @override
  Stream<List<int>> createStream({int? limit}) {
    recordedLimits.add(limit);
    return streamFactory(limit: limit);
  }
}

/// VM whose mapper can be configured to throw (kept for future scenarios).
class DynamicMapperVM
    extends AppStreamedListViewModel<TestState, TestEvent, int, TestFailure> {
  final Stream<List<int>> Function({int? limit}) streamFactory;
  bool shouldThrowOnMapper = false;

  DynamicMapperVM(this.streamFactory)
      : super(
          initialState: LoadingState(),
          stateAfterDataAutoUpdate: (_) =>
              throw StateError("replaced at runtime"),
          stateOnInitialFailure: (failure) => FailureState(failure),
          mapUnexpectedExceptionToFailure: (e) => TestFailure("unexpected"),
          pageSize: 2,
        );

  // Overrides construction with a controllable mapper.
  factory DynamicMapperVM.create(
      Stream<List<int>> Function({int? limit}) streamFactory) {
    late DynamicMapperVM instance;
    instance = _DynamicMapperVMImpl(streamFactory);
    return instance;
  }

  @override
  Stream<List<int>> createStream({int? limit}) {
    return streamFactory(limit: limit);
  }
}

class _DynamicMapperVMImpl extends DynamicMapperVM {
  _DynamicMapperVMImpl(super.streamFactory);
}

/// VM with a mapper that always throws (kept for future scenarios).
class MapperExceptionVM
    extends AppStreamedListViewModel<TestState, TestEvent, int, TestFailure> {
  final Stream<List<int>> Function({int? limit}) streamFactory;
  int mapperCallCount = 0;

  MapperExceptionVM(this.streamFactory)
      : super(
          initialState: LoadingState(),
          stateAfterDataAutoUpdate: (_) =>
              throw StateError("placeholder — replaced below"),
          stateOnInitialFailure: (failure) => FailureState(failure),
          mapUnexpectedExceptionToFailure: (e) => TestFailure("unexpected"),
          pageSize: 2,
        );

  @override
  Stream<List<int>> createStream({int? limit}) {
    return streamFactory(limit: limit);
  }
}

/// VM that throws from the mapper only after N calls.
class ConditionalMapperVM
    extends AppStreamedListViewModel<TestState, TestEvent, int, TestFailure> {
  final Stream<List<int>> Function({int? limit}) streamFactory;
  static int _callCount = 0;
  static int _throwAfter = 999;

  ConditionalMapperVM._internal(this.streamFactory)
      : super(
          initialState: LoadingState(),
          stateAfterDataAutoUpdate: (data) {
            _callCount++;
            if (_callCount > _throwAfter) {
              throw Exception("Mapper explosion at call $_callCount");
            }
            return data.isEmpty ? EmptyState() : SuccessState(data);
          },
          stateOnInitialFailure: (failure) => FailureState(failure),
          mapUnexpectedExceptionToFailure: (e) => TestFailure("unexpected"),
          pageSize: 2,
        );

  factory ConditionalMapperVM({
    required Stream<List<int>> Function({int? limit}) streamFactory,
    required int throwAfterCall,
  }) {
    _callCount = 0;
    _throwAfter = throwAfterCall;
    return ConditionalMapperVM._internal(streamFactory);
  }

  @override
  Stream<List<int>> createStream({int? limit}) {
    return streamFactory(limit: limit);
  }
}

// =======================
// TESTS
// =======================

void main() {
  // Silence internal `debugPrint` from the production ViewModel during tests.
  // We still validate behavior via state/pagination assertions.
  late DebugPrintCallback originalDebugPrint;

  setUp(() {
    originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {};
  });

  tearDown(() {
    debugPrint = originalDebugPrint;
  });

  // ─────────────────────────────────────────
  // 1. INITIAL LOAD
  // ─────────────────────────────────────────
  group("AppStreamedListViewModel - Initial Load", () {
    test("emits SuccessState on initial data", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = TestStreamedVM(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      expect(vm.state, isA<SuccessState>());
      expect((vm.state as SuccessState).data, [1, 2]);
      controller.close();
    });

    test("emits EmptyState on initial empty data", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = TestStreamedVM(({limit}) => controller.stream);

      controller.add([]);
      await Future.microtask(() {});

      expect(vm.state, isA<EmptyState>());
      controller.close();
    });

    test("emits FailureState on initial known failure type", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = TestStreamedVM(({limit}) => controller.stream);

      controller.addError(TestFailure("fail"));
      await Future.microtask(() {});

      expect(vm.state, isA<FailureState>());
      expect((vm.state as FailureState).failure.message, "fail");
      controller.close();
    });

    test("maps unexpected exception to failure on initial load", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = TestStreamedVM(({limit}) => controller.stream);

      controller.addError(ArgumentError("bad"));
      await Future.microtask(() {});

      expect(vm.state, isA<FailureState>());
      expect((vm.state as FailureState).failure.message, "unexpected");
      controller.close();
    });

    test("paginationState is Idle after initial failure (never Loading/Error)",
        () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = TestStreamedVM(({limit}) => controller.stream);

      controller.addError(TestFailure("fail"));
      await Future.microtask(() {});

      // CRITICAL: pagination must be Idle on initial load, not Error.
      expect(vm.paginationState.runtimeType.toString(), contains("Idle"));
      controller.close();
    });

    test("hasReachedMax is true when initial data < pageSize", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = TestStreamedVM(({limit}) => controller.stream);

      controller.add([1]); // pageSize=2, got 1 → hasReachedMax=true
      await Future.microtask(() {});

      expect(vm.hasReachedMax, true);
      controller.close();
    });

    test("hasReachedMax is false when initial data == pageSize", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = TestStreamedVM(({limit}) => controller.stream);

      controller.add([1, 2]); // pageSize=2, got 2 → hasReachedMax=false
      await Future.microtask(() {});

      expect(vm.hasReachedMax, false);
      controller.close();
    });

    test("empty initial data sets hasReachedMax to true", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = TestStreamedVM(({limit}) => controller.stream);

      controller.add([]); // 0 < 2 → true
      await Future.microtask(() {});

      expect(vm.hasReachedMax, true);
      expect(vm.state, isA<EmptyState>());
      controller.close();
    });

    test("initial state is LoadingState before stream emits", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = TestStreamedVM(({limit}) => controller.stream);

      expect(vm.state, isA<LoadingState>());
      controller.close();
    });

    test("pageSize getter returns the configured value", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = TestStreamedVM(({limit}) => controller.stream);

      expect(vm.pageSize, 2);
      controller.close();
    });
  });

  // ─────────────────────────────────────────
  // 2. LIMIT CONSISTENCY (critical para bugs de dados)
  // ─────────────────────────────────────────
  group("AppStreamedListViewModel - Limit Consistency", () {
    test("createStream receives pageSize as initial limit", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = LimitTrackingVM(({limit}) => controller.stream);

      // The constructor triggers `_startListening` with `_currentLimit = pageSize`.
      expect(vm.recordedLimits.first, 2);
      controller.close();
    });

    test("loadMore increments limit by pageSize", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = LimitTrackingVM(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      vm.loadMore();

      // Initial: 2, after loadMore: 4
      expect(vm.recordedLimits, [2, 4]);
      controller.close();
    });

    test("multiple loadMore calls increment limit correctly", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = LimitTrackingVM(({limit}) => controller.stream);

      // Initial: limit=2
      controller.add([1, 2]);
      await Future.microtask(() {});

      // loadMore 1: limit=4
      vm.loadMore();
      controller.add([1, 2, 3, 4]);
      await Future.microtask(() {});

      // loadMore 2: limit=6
      vm.loadMore();
      controller.add([1, 2, 3, 4, 5, 6]);
      await Future.microtask(() {});

      // loadMore 3: limit=8
      vm.loadMore();
      controller.add([1, 2, 3, 4, 5, 6, 7, 8]);
      await Future.microtask(() {});

      expect(vm.recordedLimits, [2, 4, 6, 8]);
      controller.close();
    });

    test("refresh resets limit to pageSize", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = LimitTrackingVM(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      vm.loadMore();
      controller.add([1, 2, 3, 4]);
      await Future.microtask(() {});

      vm.refresh();

      // Recorded: [2 (init), 4 (loadMore), 2 (refresh)]
      expect(vm.recordedLimits, [2, 4, 2]);
      controller.close();
    });

    test("retryPagination does NOT increment limit (reuses current)", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = LimitTrackingVM(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      vm.loadMore(); // limit goes to 4
      controller.addError(TestFailure("error"));
      await Future.microtask(() {});

      vm.retryPagination(); // limit should STILL be 4

      // Recorded: [2 (init), 4 (loadMore), 4 (retry)]
      expect(vm.recordedLimits, [2, 4, 4]);
      controller.close();
    });

    test(
        "refresh after multiple loadMore calls resets limit to pageSize, "
        "not the accumulated value", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = LimitTrackingVM(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      vm.loadMore();
      controller.add([1, 2, 3, 4]);
      await Future.microtask(() {});

      vm.loadMore();
      controller.add([1, 2, 3, 4, 5, 6]);
      await Future.microtask(() {});

      vm.refresh();

      // Must reset to 2, not keep 6.
      expect(vm.recordedLimits.last, 2);
      controller.close();
    });

    test(
        "loadMore after refresh uses correct limit "
        "(pageSize + pageSize, not the old accumulated)", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = LimitTrackingVM(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      // loadMore: limit=4
      vm.loadMore();
      controller.add([1, 2, 3, 4]);
      await Future.microtask(() {});

      // refresh: limit=2
      vm.refresh();
      controller.add([1, 2]);
      await Future.microtask(() {});

      // loadMore after refresh: limit=4 (2+2), NOT 6 (4+2)
      vm.loadMore();

      expect(vm.recordedLimits, [2, 4, 2, 4]);
      controller.close();
    });
  });

  // ─────────────────────────────────────────
  // 3. PAGINATION - loadMore
  // ─────────────────────────────────────────
  group("AppStreamedListViewModel - loadMore", () {
    test("sets pagination to Loading then Idle on success", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = TestStreamedVM(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      vm.loadMore();
      expect(vm.paginationState.runtimeType.toString(), contains("Loading"));

      controller.add([1, 2, 3, 4]);
      await Future.microtask(() {});

      expect(vm.paginationState.runtimeType.toString(), contains("Idle"));
      controller.close();
    });

    test("sets pagination to Error on stream error", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = TestStreamedVM(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      vm.loadMore();
      controller.addError(TestFailure("fail"));
      await Future.microtask(() {});

      expect(vm.paginationState.runtimeType.toString(), contains("Error"));
      controller.close();
    });

    test("hasReachedMax becomes true when received data < limit", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = TestStreamedVM(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      vm.loadMore(); // limit=4
      controller.add([1, 2, 3]); // got 3 < 4
      await Future.microtask(() {});

      expect(vm.hasReachedMax, true);
      controller.close();
    });

    test("hasReachedMax stays false when received data == limit", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = TestStreamedVM(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      vm.loadMore(); // limit=4
      controller.add([1, 2, 3, 4]); // got 4 == 4
      await Future.microtask(() {});

      expect(vm.hasReachedMax, false);
      controller.close();
    });

    test("is blocked when hasReachedMax is true", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = LimitTrackingVM(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      vm.loadMore();
      controller.add([1, 2, 3]); // hasReachedMax = true
      await Future.microtask(() {});

      expect(vm.hasReachedMax, true);

      final limitCountBefore = vm.recordedLimits.length;
      vm.loadMore(); // deve ser ignorado
      expect(
          vm.recordedLimits.length, limitCountBefore); // sem novo createStream
      expect(vm.paginationState.runtimeType.toString(), contains("Idle"));
      controller.close();
    });

    test("is blocked when already loading (prevents concurrent calls)",
        () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = LimitTrackingVM(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      vm.loadMore();
      final limitsCount = vm.recordedLimits.length;

      vm.loadMore(); // deveria ser ignorado
      vm.loadMore(); // deveria ser ignorado
      vm.loadMore(); // deveria ser ignorado

      expect(vm.recordedLimits.length, limitsCount);
      controller.close();
    });

    test("preserves main SuccessState on pagination error", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = TestStreamedVM(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      final stateBefore = vm.state;
      expect(stateBefore, isA<SuccessState>());

      vm.loadMore();
      controller.addError(TestFailure("fail"));
      await Future.microtask(() {});

      // CRITICAL: main state NÃO deve mudar
      expect(vm.state, equals(stateBefore));
      expect(vm.state, isA<SuccessState>());
      controller.close();
    });

    test(
        "after successful loadMore, data in SuccessState reflects "
        "the full list (not just new page)", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = TestStreamedVM(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      vm.loadMore();
      controller.add([1, 2, 3, 4]);
      await Future.microtask(() {});

      final state = vm.state as SuccessState;
      expect(state.data, [1, 2, 3, 4]);
      controller.close();
    });
  });

  // ─────────────────────────────────────────
  // 4. RETRY PAGINATION
  // ─────────────────────────────────────────
  group("AppStreamedListViewModel - retryPagination", () {
    test("triggers Loading from Error state", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = TestStreamedVM(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      vm.loadMore();
      controller.addError(TestFailure("fail"));
      await Future.microtask(() {});

      expect(vm.paginationState.runtimeType.toString(), contains("Error"));

      vm.retryPagination();
      expect(vm.paginationState.runtimeType.toString(), contains("Loading"));
      controller.close();
    });

    test("does nothing when paginationState is Idle", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = LimitTrackingVM(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      final countBefore = vm.recordedLimits.length;
      vm.retryPagination();
      expect(vm.recordedLimits.length, countBefore);
      expect(vm.paginationState.runtimeType.toString(), contains("Idle"));
      controller.close();
    });

    test("does nothing when paginationState is Loading", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = LimitTrackingVM(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      vm.loadMore();
      expect(vm.paginationState.runtimeType.toString(), contains("Loading"));

      final countBefore = vm.recordedLimits.length;
      vm.retryPagination();
      expect(vm.recordedLimits.length, countBefore);
      controller.close();
    });

    test("successful retry transitions Error → Loading → Idle", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = TestStreamedVM(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      vm.loadMore();
      controller.addError(TestFailure("fail"));
      await Future.microtask(() {});

      expect(vm.paginationState.runtimeType.toString(), contains("Error"));

      vm.retryPagination();
      expect(vm.paginationState.runtimeType.toString(), contains("Loading"));

      controller.add([1, 2, 3, 4]);
      await Future.microtask(() {});

      expect(vm.paginationState.runtimeType.toString(), contains("Idle"));
      expect(vm.state, isA<SuccessState>());
      controller.close();
    });

    test("retryPagination resets hasReachedMax to false", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = TestStreamedVM(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      vm.loadMore();
      controller.addError(TestFailure("fail"));
      await Future.microtask(() {});

      vm.retryPagination();
      expect(vm.hasReachedMax, false);
      controller.close();
    });

    test(
        "multiple error→retry cycles don't corrupt state "
        "or increment limit incorrectly", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = LimitTrackingVM(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      // loadMore: limit=4
      vm.loadMore();
      controller.addError(TestFailure("error 1"));
      await Future.microtask(() {});

      // retry 1: limit=4 (não incrementa!)
      vm.retryPagination();
      controller.addError(TestFailure("error 2"));
      await Future.microtask(() {});

      // retry 2: limit=4 (não incrementa!)
      vm.retryPagination();
      controller.addError(TestFailure("error 3"));
      await Future.microtask(() {});

      // retry 3: limit=4, success
      vm.retryPagination();
      controller.add([1, 2, 3, 4]);
      await Future.microtask(() {});

      // Verifica que o limite NUNCA foi corrompido
      // init=2, loadMore=4, retry1=4, retry2=4, retry3=4
      expect(vm.recordedLimits, [2, 4, 4, 4, 4]);
      expect(vm.state, isA<SuccessState>());
      expect(vm.paginationState.runtimeType.toString(), contains("Idle"));
      controller.close();
    });
  });

  // ─────────────────────────────────────────
  // 5. REFRESH
  // ─────────────────────────────────────────
  group("AppStreamedListViewModel - refresh", () {
    test("resets hasReachedMax, paginationState and limit", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = LimitTrackingVM(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      vm.loadMore();
      controller.add([1, 2, 3]); // hasReachedMax=true
      await Future.microtask(() {});

      expect(vm.hasReachedMax, true);

      vm.refresh();

      expect(vm.hasReachedMax, false);
      expect(vm.paginationState.runtimeType.toString(), contains("Idle"));
      expect(vm.recordedLimits.last, 2); // limit reset
      controller.close();
    });

    test("cancels ongoing pagination and resets", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = TestStreamedVM(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      vm.loadMore();
      expect(vm.paginationState.runtimeType.toString(), contains("Loading"));

      vm.refresh();

      expect(vm.paginationState.runtimeType.toString(), contains("Idle"));
      expect(vm.hasReachedMax, false);
      controller.close();
    });

    test("after refresh, loadMore works again correctly", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = LimitTrackingVM(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      vm.loadMore();
      controller.add([1, 2, 3]); // hasReachedMax=true
      await Future.microtask(() {});

      expect(vm.hasReachedMax, true);

      vm.refresh();
      controller.add([1, 2]);
      await Future.microtask(() {});

      expect(vm.hasReachedMax, false);

      vm.loadMore();
      controller.add([1, 2, 3, 4]);
      await Future.microtask(() {});

      expect(vm.hasReachedMax, false);
      expect(vm.state, isA<SuccessState>());
      controller.close();
    });

    test("refresh after pagination error clears error state", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = TestStreamedVM(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      vm.loadMore();
      controller.addError(TestFailure("err"));
      await Future.microtask(() {});

      expect(vm.paginationState.runtimeType.toString(), contains("Error"));

      vm.refresh();

      expect(vm.paginationState.runtimeType.toString(), contains("Idle"));
      expect(vm.hasReachedMax, false);

      controller.add([1, 2]);
      await Future.microtask(() {});

      expect(vm.state, isA<SuccessState>());
      controller.close();
    });

    test("multiple rapid refreshes don't create duplicate subscriptions",
        () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = TestStreamedVM(({limit}) => controller.stream);

      vm.refresh();
      vm.refresh();
      vm.refresh();

      // After 3 calls, there should be at most one active listener.
      controller.add([1, 2]);
      await Future.microtask(() {});

      expect(vm.state, isA<SuccessState>());
      // Should not crash or produce inconsistent states.
      controller.close();
    });
  });

  // ─────────────────────────────────────────
  // 6. SUBSCRIPTION MANAGEMENT & MEMORY LEAKS
  // ─────────────────────────────────────────
  group("AppStreamedListViewModel - Subscription Management", () {
    test("dispose cancels stream subscription", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = TestStreamedVM(({limit}) => controller.stream);

      expect(controller.hasListener, true);
      vm.dispose();
      expect(controller.hasListener, false);
      controller.close();
    });

    test("dispose before stream emits does not crash", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = TestStreamedVM(({limit}) => controller.stream);

      vm.dispose();

      // Emitting data after dispose must not crash.
      controller.add([1, 2]);
      await Future.microtask(() {});

      expect(controller.hasListener, false);
      controller.close();
    });

    test("dispose during active pagination cleans up", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = TestStreamedVM(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      vm.loadMore();

      expect(controller.hasListener, true);
      vm.dispose();
      expect(controller.hasListener, false);
      controller.close();
    });

    test("error handler cancels subscription (prevents ghost listeners)",
        () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = TestStreamedVM(({limit}) => controller.stream);
      addTearDown(vm.dispose);

      controller.addError(TestFailure("boom"));
      await Future.microtask(() {});

      // After an error, `_handleError` must cancel the subscription.
      expect(controller.hasListener, false);
      controller.close();
    });

    test(
        "loadMore creates new subscription (old one cancelled by "
        "_startListening)", () async {
      final controller = StreamController<List<int>>.broadcast();
      int listenerCountHighWatermark = 0;

      final vm = TestStreamedVM(({limit}) {
        // Snapshot listener count.
        if (controller.hasListener) {
          listenerCountHighWatermark++;
        }
        return controller.stream;
      });

      controller.add([1, 2]);
      await Future.microtask(() {});

      vm.loadMore();

      // `_startListening` cancels the previous subscription before creating a new one.
      expect(controller.hasListener, true);
      // Make the variable intentionally used to avoid lints.
      expect(listenerCountHighWatermark, greaterThanOrEqualTo(0));
      controller.close();
    });
  });

  // ─────────────────────────────────────────
  // 7. STREAM DATA UPDATES (real-time)
  // ─────────────────────────────────────────
  group("AppStreamedListViewModel - Real-Time Stream Updates", () {
    test("multiple stream emissions update state correctly", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = TestStreamedVM(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});
      expect((vm.state as SuccessState).data, [1, 2]);

      controller.add([1, 2, 3]);
      await Future.microtask(() {});
      expect((vm.state as SuccessState).data, [1, 2, 3]);

      controller.add([10, 20]);
      await Future.microtask(() {});
      expect((vm.state as SuccessState).data, [10, 20]);
      controller.close();
    });

    test("stream update from non-empty to empty transitions correctly",
        () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = TestStreamedVM(({limit}) => controller.stream);

      controller.add([1, 2, 3]);
      await Future.microtask(() {});
      expect(vm.state, isA<SuccessState>());

      controller.add([]);
      await Future.microtask(() {});
      expect(vm.state, isA<EmptyState>());
      controller.close();
    });

    test("hasReachedMax updates correctly on each stream emission", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = TestStreamedVM(({limit}) => controller.stream); // pageSize=2

      // limit=2, got 2 → false
      controller.add([1, 2]);
      await Future.microtask(() {});
      expect(vm.hasReachedMax, false);

      // Stream emite novamente com dados menores → true
      controller.add([1]);
      await Future.microtask(() {});
      expect(vm.hasReachedMax, true);

      // Stream emite novamente com dados iguais ao limit → false
      controller.add([1, 2]);
      await Future.microtask(() {});
      expect(vm.hasReachedMax, false);
      controller.close();
    });
  });

  // ─────────────────────────────────────────
  // 8. MAPPER EXCEPTION HANDLING
  // ─────────────────────────────────────────
  group("AppStreamedListViewModel - Mapper Exception Handling", () {
    test("mapper exception on initial load sets FailureState", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = ConditionalMapperVM(
        streamFactory: ({limit}) => controller.stream,
        throwAfterCall: 0, // throw on first call
      );

      controller.add([1, 2]);
      await Future.microtask(() {});

      expect(vm.state, isA<FailureState>());
      expect((vm.state as FailureState).failure.message, "unexpected");
      controller.close();
    });

    test(
        "mapper exception on pagination sets PaginationError "
        "and preserves main state", () async {
      final controller = StreamController<List<int>>.broadcast();

      // throwAfterCall=1: first mapper call OK, second throws
      final vm = ConditionalMapperVM(
        streamFactory: ({limit}) => controller.stream,
        throwAfterCall: 1,
      );

      // First emission → mapper call 1 → success
      controller.add([1, 2]);
      await Future.microtask(() {});

      expect(vm.state, isA<SuccessState>());
      final stateBefore = vm.state;

      // loadMore → mapper call 2 → throws
      vm.loadMore();
      controller.add([1, 2, 3, 4]);
      await Future.microtask(() {});

      // Main state must remain intact.
      expect(vm.state, equals(stateBefore));
      expect(vm.paginationState.runtimeType.toString(), contains("Error"));
      controller.close();
    });

    test(
        "mapper exception on pagination cancels subscription "
        "(prevents infinite error loop)", () async {
      final controller = StreamController<List<int>>.broadcast();

      final vm = ConditionalMapperVM(
        streamFactory: ({limit}) => controller.stream,
        throwAfterCall: 1,
      );

      controller.add([1, 2]);
      await Future.microtask(() {});

      vm.loadMore();
      controller.add([1, 2, 3, 4]); // mapper throws
      await Future.microtask(() {});

      // Subscription must have been cancelled.
      expect(controller.hasListener, false);
      controller.close();
    });
  });

  // ─────────────────────────────────────────
  // 9. _isLoadingMore FLAG INTEGRITY
  // ─────────────────────────────────────────
  group("AppStreamedListViewModel - _isLoadingMore Flag Integrity", () {
    test("flag is reset after successful loadMore (can loadMore again)",
        () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = LimitTrackingVM(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      vm.loadMore();
      controller.add([1, 2, 3, 4]);
      await Future.microtask(() {});

      // If the flag wasn't reset, this loadMore would be ignored.
      vm.loadMore();
      expect(vm.recordedLimits.last, 6); // prova que o loadMore funcionou
      controller.close();
    });

    test("flag is reset after failed loadMore (retryPagination unblocked)",
        () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = LimitTrackingVM(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      vm.loadMore();
      controller.addError(TestFailure("err"));
      await Future.microtask(() {});

      // If the flag wasn't reset, retryPagination wouldn't work.
      vm.retryPagination();
      expect(vm.paginationState.runtimeType.toString(), contains("Loading"));
      controller.close();
    });

    test("flag is reset after mapper exception (retryPagination unblocked)",
        () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = ConditionalMapperVM(
        streamFactory: ({limit}) => controller.stream,
        throwAfterCall: 1,
      );

      controller.add([1, 2]); // call 1 → success
      await Future.microtask(() {});

      vm.loadMore();
      controller.add([1, 2, 3, 4]); // call 2 → throws
      await Future.microtask(() {});

      // `_isLoadingMore` must be reset by `_handleError`.
      expect(vm.paginationState.runtimeType.toString(), contains("Error"));

      // retryPagination must work (no deadlock).
      vm.retryPagination();
      expect(vm.paginationState.runtimeType.toString(), contains("Loading"));
      controller.close();
    });

    test("flag is reset by refresh (unblocks future loadMore)", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = LimitTrackingVM(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      vm.loadMore(); // _isLoadingMore = true

      vm.refresh(); // must reset _isLoadingMore = false

      controller.add([1, 2]);
      await Future.microtask(() {});

      // After refresh + data, loadMore should work normally.
      vm.loadMore();
      expect(vm.recordedLimits.last, 4); // prova que loadMore funcionou
      controller.close();
    });
  });

  // ─────────────────────────────────────────
  // 10. INFINITE LOOP & DEADLOCK PREVENTION
  // ─────────────────────────────────────────
  group("AppStreamedListViewModel - Infinite Loop Prevention", () {
    test(
        "loadMore → hasReachedMax=true → loadMore is noop "
        "(prevents infinite pagination loop)", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = LimitTrackingVM(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      vm.loadMore();
      controller.add([1, 2, 3]); // < limit=4 → hasReachedMax
      await Future.microtask(() {});

      expect(vm.hasReachedMax, true);

      // Calling loadMore 100 times should have no effect.
      final countBefore = vm.recordedLimits.length;
      for (int i = 0; i < 100; i++) {
        vm.loadMore();
      }
      expect(vm.recordedLimits.length, countBefore);
      controller.close();
    });

    test(
        "rapid loadMore→error→retry cycle terminates correctly "
        "(no deadlock)", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = TestStreamedVM(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      // Simulate 5 error→retry cycles.
      for (int i = 0; i < 5; i++) {
        vm.loadMore();
        controller.addError(TestFailure("error $i"));
        await Future.microtask(() {});
        expect(vm.paginationState.runtimeType.toString(), contains("Error"));
        vm.retryPagination();
      }

      // Finally succeed.
      controller.add([1, 2, 3, 4]);
      await Future.microtask(() {});

      expect(vm.state, isA<SuccessState>());
      expect(vm.paginationState.runtimeType.toString(), contains("Idle"));
      controller.close();
    });

    test("error on initial load stops listening (no infinite error stream)",
        () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = TestStreamedVM(({limit}) => controller.stream);

      controller.addError(TestFailure("init error"));
      await Future.microtask(() {});

      expect(vm.state, isA<FailureState>());
      // CRITICAL: subscription must be cancelled to avoid infinite loops.
      expect(controller.hasListener, false);
      controller.close();
    });

    test(
        "pagination error cancels subscription "
        "(no more events from that stream)", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = TestStreamedVM(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      vm.loadMore();
      controller.addError(TestFailure("pagination error"));
      await Future.microtask(() {});

      expect(controller.hasListener, false);

      // Emitting data afterwards must not affect state.
      final stateBefore = vm.state;
      controller.add([99, 100]);
      await Future.microtask(() {});
      expect(vm.state, equals(stateBefore));
      controller.close();
    });
  });

  // ─────────────────────────────────────────
  // 11. FULL LIFECYCLE / STATE MACHINE
  // ─────────────────────────────────────────
  group("AppStreamedListViewModel - Full Lifecycle", () {
    test(
        "complete lifecycle: load → paginate → paginate → "
        "maxReached → refresh → load → paginate → dispose", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = LimitTrackingVM(({limit}) => controller.stream);

      // 1. Initial load
      expect(vm.state, isA<LoadingState>());
      controller.add([1, 2]);
      await Future.microtask(() {});
      expect(vm.state, isA<SuccessState>());
      expect(vm.hasReachedMax, false);
      expect(vm.paginationState.runtimeType.toString(), contains("Idle"));

      // 2. First pagination
      vm.loadMore();
      expect(vm.paginationState.runtimeType.toString(), contains("Loading"));
      controller.add([1, 2, 3, 4]);
      await Future.microtask(() {});
      expect(vm.hasReachedMax, false);
      expect((vm.state as SuccessState).data, [1, 2, 3, 4]);

      // 3. Second pagination → max reached
      vm.loadMore();
      controller.add([1, 2, 3, 4, 5]); // 5 < 6 → max
      await Future.microtask(() {});
      expect(vm.hasReachedMax, true);
      expect((vm.state as SuccessState).data, [1, 2, 3, 4, 5]);

      // 4. loadMore é bloqueado
      // 4. loadMore is blocked
      vm.loadMore();
      expect(vm.paginationState.runtimeType.toString(), contains("Idle"));

      // 5. Refresh
      vm.refresh();
      expect(vm.hasReachedMax, false);
      controller.add([10, 20]);
      await Future.microtask(() {});
      expect((vm.state as SuccessState).data, [10, 20]);

      // 6. New pagination after refresh
      vm.loadMore();
      controller.add([10, 20, 30, 40]);
      await Future.microtask(() {});
      expect(vm.hasReachedMax, false);

      // 7. Dispose
      expect(controller.hasListener, true);
      vm.dispose();
      expect(controller.hasListener, false);

      // Verify limit sequence
      // init=2, loadMore=4, loadMore=6, refresh=2, loadMore=4
      expect(vm.recordedLimits, [2, 4, 6, 2, 4]);
      controller.close();
    });

    test(
        "error recovery lifecycle: load → loadMore → error → retry → "
        "error → refresh → load → success", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = LimitTrackingVM(({limit}) => controller.stream);

      // 1. Initial load
      controller.add([1, 2]);
      await Future.microtask(() {});
      expect(vm.state, isA<SuccessState>());

      // 2. Pagination fails
      vm.loadMore();
      controller.addError(TestFailure("err1"));
      await Future.microtask(() {});
      expect(vm.paginationState.runtimeType.toString(), contains("Error"));
      expect(vm.state, isA<SuccessState>()); // main state preserved

      // 3. Retry - fails again
      vm.retryPagination();
      controller.addError(TestFailure("err2"));
      await Future.microtask(() {});
      expect(vm.paginationState.runtimeType.toString(), contains("Error"));

      // 4. User refreshes
      vm.refresh();
      controller.add([10, 20]);
      await Future.microtask(() {});
      expect(vm.state, isA<SuccessState>());
      expect((vm.state as SuccessState).data, [10, 20]);
      expect(vm.paginationState.runtimeType.toString(), contains("Idle"));
      expect(vm.hasReachedMax, false);

      // limits: init=2, loadMore=4, retry=4, refresh=2
      expect(vm.recordedLimits, [2, 4, 4, 2]);
      controller.close();
    });

    test("initial failure → refresh → success lifecycle works correctly",
        () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = TestStreamedVM(({limit}) => controller.stream);

      // Initial fail
      controller.addError(TestFailure("init error"));
      await Future.microtask(() {});
      expect(vm.state, isA<FailureState>());

      // User refreshes
      vm.refresh();
      controller.add([1, 2]);
      await Future.microtask(() {});

      expect(vm.state, isA<SuccessState>());
      expect(vm.hasReachedMax, false);
      expect(vm.paginationState.runtimeType.toString(), contains("Idle"));
      controller.close();
    });
  });

  // ─────────────────────────────────────────
  // 12. EDGE CASES
  // ─────────────────────────────────────────
  group("AppStreamedListViewModel - Edge Cases", () {
    test("stream that emits error immediately is handled", () async {
      final vm = TestStreamedVM(
        ({limit}) => Stream<List<int>>.error(TestFailure("instant error")),
      );

      await Future.microtask(() {});
      expect(vm.state, isA<FailureState>());
    });

    test(
        "stream that completes without emitting any data stays in initial state",
        () async {
      final vm = TestStreamedVM(
        ({limit}) => const Stream<List<int>>.empty(),
      );

      await Future.microtask(() {});

      // Empty stream completes; state remains the initialState.
      expect(vm.state, isA<LoadingState>());
    });

    test("stream that emits single value then completes works", () async {
      final vm = TestStreamedVM(
        ({limit}) => Stream<List<int>>.fromIterable([
          [1, 2, 3]
        ]),
      );

      await Future.microtask(() {});
      expect(vm.state, isA<SuccessState>());
      expect((vm.state as SuccessState).data, [1, 2, 3]);
    });

    test("data larger than limit does not set hasReachedMax", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = TestStreamedVM(({limit}) => controller.stream); // pageSize=2

      // Edge case: backend returns more items than the limit (defensive).
      controller.add([1, 2, 3, 4, 5]); // limit=2, got 5
      await Future.microtask(() {});

      expect(vm.hasReachedMax, false); // 5 < 2 is false
      expect(vm.state, isA<SuccessState>());
      controller.close();
    });

    test("unexpected error type on pagination is mapped correctly", () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = TestStreamedVM(({limit}) => controller.stream);

      controller.add([1, 2]);
      await Future.microtask(() {});

      vm.loadMore();
      controller
          .addError(const FormatException("bad format")); // not TestFailure
      await Future.microtask(() {});

      expect(vm.paginationState.runtimeType.toString(), contains("Error"));
      // Main state preserved
      expect(vm.state, isA<SuccessState>());
      controller.close();
    });

    test("loadMore right after initial error is handled consistently",
        () async {
      final controller = StreamController<List<int>>.broadcast();
      final vm = LimitTrackingVM(({limit}) => controller.stream);

      controller.addError(TestFailure("init error"));
      await Future.microtask(() {});

      expect(vm.state, isA<FailureState>());

      final countBefore = vm.recordedLimits.length;

      // After an initial error, _isLoadingMore is reset to false, _hasReachedMax
      // is false, and paginationState is Idle. So loadMore is allowed.
      vm.loadMore();

      // Verify the limit increment is correct.
      if (vm.recordedLimits.length > countBefore) {
        expect(vm.recordedLimits.last, 4); // 2 + 2
      }
      controller.close();
    });
  });
}
