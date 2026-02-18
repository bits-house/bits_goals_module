import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:bits_goals_module/src/core/presentation/state_management/view_model/impl/app_view_model.dart';
import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_dart/reactivity_impl/app_observable.dart';

/// A specialized [AppViewModel] designed for **Limit-Based Infinite Scrolling** fetching with
/// **Robust Error Handling** and **Real-Time Stream Updates**.
///
/// Note: Not made for page-based APIs where you need to keep the old data while fetching new pages.
///
/// It separates the **Main Screen State** (the list itself) from the **Pagination State** (the footer),
/// ensuring a smooth UX where the user never loses context of the existing data.
///
/// ### Generics:
/// [S] - Main State Type. MUST be a sealed class representing the entire screen state.
/// [E] - Event Type. MUST be a sealed class representing one-off events (navigation, snackbars, etc).
/// [T] - List Item Type
/// [F] - Domain Failure Type
abstract class AppStreamedListViewModel<S, E, T, F> extends AppViewModel<S, E> {
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
  ///   TestViewModel(
  ///     GetItensUseCase useCase,
  ///   ) : super(
  ///           initialState: LoadingState(),
  ///           stateAfterDataAutoUpdate: (data) {
  ///             if (data.isEmpty) {
  ///               return EmptyState();
  ///             } else {
  ///               return SuccessState();
  ///             }
  ///           },
  ///           stateOnInitialFailure: (failure) => FailureState(
  ///             failure: failure,
  ///           ),
  ///           mapUnexpectedExceptionToFailure: (exception) => Failure(
  ///             reason: FailureReason.unexpected,
  ///           ),
  ///         );
  AppStreamedListViewModel({
    required super.initialState,
    required S Function(List<T> data) stateAfterDataAutoUpdate,
    required S Function(F failure) stateOnInitialFailure,
    required F Function(Object exception) mapUnexpectedExceptionToFailure,
    int pageSize = 20,
  })  : _mainStateMapper = stateAfterDataAutoUpdate,
        _initialFailureHandler = stateOnInitialFailure,
        _exceptionMapper = mapUnexpectedExceptionToFailure,
        _pageSize = pageSize {
    _currentLimit = _pageSize;
    _startListening(isInitialLoad: true);
  }

  // ================= MANDATORY SETUP =================

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
          debugPrint("[AppStreamedListVM] Mapper Error: $e\n$s");
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
      debugPrint("[AppStreamedListVM] Stream Error: $error");
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
