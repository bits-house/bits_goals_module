import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_flutter/stores/impl/app_store.dart';
import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_dart/reactivity_impl/app_observable.dart';

/// A specialized [AppStore] designed for **Limit-Based Infinite Scrolling** fetching with
/// **Robust Error Handling** and **Real-Time Stream Updates**.
///
/// Note: Not made for page-based APIs where you need to keep the old data while fetching new pages.
///
/// It separates the **Main Screen State** (the list itself) from the **Pagination State** (the footer),
/// ensuring a smooth UX where the user never loses context of the existing data.
///
/// ### Generics:
/// [S] - Main State Type. MUST be a sealed class representing the entire screen state.
/// [E] - Effect Type. MUST be a sealed class representing one-off effects (navigation, snackbars, etc).
/// [T] - List Item Type
/// [F] - Domain Failure Type
abstract class AppStreamedListStore<S, E, T, F> extends AppStore<S, E> {
  // ================= STATE =================

  StreamSubscription<List<T>>? _streamSubscription;

  final _paginationState =
      AppObservable<PaginationState<F>>(PaginationIdle<F>());

  final int _pageSize;
  late int _currentLimit;

  bool _hasReachedMax = false;

  /// Used to trigger AnimatedList rebuilds when the list changes.
  Object _listIdentity = Object();
  List<T> _items = const [];

  /// Safety flag to avoid race conditions.
  /// Because the widget can trigger multiple loadMore calls simultaneously.
  bool _isLoadingMore = false;

  bool _nextEmissionIsPaginationExpansion = false;

  final S Function(List<T>) _mainStateMapper;
  final S Function(F) _initialFailureHandler;
  final F Function(Object exception) _exceptionMapper;

  // ================= CONSTRUCTOR =================

  /// Example usage:
  /// ```dart
  ///   ExampleStore(
  ///     GetItensUseCase useCase,
  ///   ) : super(
  ///           initialState: LoadingState(),
  ///           mapDataToStateOnStreamAutoUpdate: (data) {
  ///             if (data.isEmpty) {
  ///               return EmptyState();
  ///             } else {
  ///               return SuccessState(data);
  ///             }
  ///           },
  ///           mapInitialFailureToState: (failure) => FailureState(failure),
  ///           mapExceptionToFailure: (exception) => Failure(
  ///             reason: FailureReason.unexpected,
  ///           ),
  ///         );
  AppStreamedListStore({
    required super.initialState,
    required S Function(List<T> data) mapDataToStateOnStreamAutoUpdate,
    required S Function(F failure) mapInitialFailureToState,
    required F Function(Object exception) mapExceptionToFailure,
    int pageSize = 20,
  })  : _mainStateMapper = mapDataToStateOnStreamAutoUpdate,
        _initialFailureHandler = mapInitialFailureToState,
        _exceptionMapper = mapExceptionToFailure,
        _pageSize = pageSize {
    _currentLimit = _pageSize;
    _startListening(isInitialLoad: true);
  }

  // ================= MANDATORY SETUP =================
  // TODO: Use generics to automatically create the stream, without the need
  //  to override

  /// Creates the stream with the dynamic [limit].
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Stream<List<T>> createStream({int? limit}) {
  ///   final getItens = GetItensUseCase();
  ///   return getItens(limit: limit ?? pageSize);
  /// }
  /// ```
  @protected
  Stream<List<T>> createStream({int? limit});

  // ================= PUBLIC API =================

  @protected
  void replaceListIdentity([Object? identity]) {
    _listIdentity = identity ?? Object();
  }

  int get currentItemCount => _items.length;

  Object get listIdentity => _listIdentity;

  int get pageSize => _pageSize;

  PaginationState<F> get paginationState => _paginationState.value;

  void addPaginationStateListener(VoidCallback listener) {
    _paginationState.addListener(listener);
  }

  void removePaginationStateListener(VoidCallback listener) {
    _paginationState.removeListener(listener);
  }

  bool get hasReachedMax => _hasReachedMax;

  void loadMore() {
    if (_hasReachedMax ||
        _isLoadingMore ||
        _paginationState.value is PaginationLoading<F>) {
      return;
    }
    _currentLimit += _pageSize;
    _isLoadingMore = true;
    _nextEmissionIsPaginationExpansion = true;
    _paginationState.value = PaginationLoading<F>();
    _startListening(isInitialLoad: false);
  }

  void retryPagination() {
    if (_paginationState.value is! PaginationError<F>) return;
    _hasReachedMax = false;
    _isLoadingMore = true;
    _nextEmissionIsPaginationExpansion = true;
    _paginationState.value = PaginationLoading<F>();
    _startListening(isInitialLoad: false);
  }

  /// Resets pagination and reloads the stream from scratch.
  /// Useful for pull-to-refresh or when the user wants to start over.
  /// Note: This will clear the existing list and show the loading state again.
  void refresh() {
    replaceListIdentity();
    _currentLimit = _pageSize;
    _hasReachedMax = false;
    _isLoadingMore = false;
    _paginationState.value = PaginationIdle<F>();
    _startListening(
      isInitialLoad: true,
    );
  }

  // ================= INTERNAL =================

  void _startListening({
    required bool isInitialLoad,
  }) {
    _streamSubscription?.cancel();
    _streamSubscription = null;

    _streamSubscription = createStream(limit: _currentLimit).listen(
      (data) {
        _paginationState.value = PaginationIdle<F>();
        _isLoadingMore = false;

        try {
          _items = data;
          _hasReachedMax = data.length < _currentLimit;

          if (_nextEmissionIsPaginationExpansion) {
            _nextEmissionIsPaginationExpansion = false;
          } else {
            replaceListIdentity();
          }

          setState(_mainStateMapper(data));
        } catch (e, s) {
          debugPrint("[AppStreamedListStore] Mapper Error: $e\n$s");
          _handleError(e, isInitialLoad);
        }
      },
      onError: (e) {
        _isLoadingMore = false;
        _handleError(e, isInitialLoad);
      },
    );
  }

  void _handleError(Object error, bool isInitialLoad) {
    late F failure;

    if (error is F) {
      failure = error as F;
    } else {
      debugPrint("[AppStreamedListStore] Stream Error: $error");
      failure = _exceptionMapper(error);
    }

    _streamSubscription?.cancel();
    _streamSubscription = null;
    _isLoadingMore = false;
    if (isInitialLoad) {
      _paginationState.value = PaginationIdle<F>();
      setState(_initialFailureHandler(failure));
    } else {
      _paginationState.value = PaginationError<F>(failure);
    }
  }

  @override
  @mustCallSuper
  void dispose() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _paginationState.dispose();
    super.dispose();
  }
}

// ================= PAGINATION STATES =================

sealed class PaginationState<F> {
  const PaginationState();
}

class PaginationIdle<F> extends PaginationState<F> {
  const PaginationIdle();
}

class PaginationLoading<F> extends PaginationState<F> {
  const PaginationLoading();
}

class PaginationError<F> extends PaginationState<F> {
  final F failure;
  const PaginationError(this.failure);
}
