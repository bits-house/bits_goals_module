import 'package:bits_goals_module/src/core/application/ports/transaction/transaction_runner.dart';

/// A storage-agnostic transaction interface.
///
/// `AppTransaction` enables multiple modules/packages/applications to participate in the same
/// synchronous and atomic transaction without being coupled to a specific
/// persistence technology (e.g. Firestore, SQLite, PostgreSQL) or same function call stack.
///
/// Used in conjunction with [TransactionRunner].
abstract class AppTransaction {
  /// Creates or replaces a resource.
  ///
  /// Semantically represents an **upsert** operation.
  ///
  /// Behavior depends on the underlying implementation:
  ///
  /// - Firestore → `set`
  /// - SQL → `insert` or `upsert`
  ///
  /// [resource] represents a logical container:
  /// - Firestore → collection path
  /// - SQL → table name
  ///
  /// [id] represents the unique identifier of the resource.
  /// It may be:
  /// - a simple key (e.g. String UUID)
  /// - a composite key (e.g. Map for SQL PKs)
  ///
  /// [data] is the serialized representation of the resource.
  Future<void> put({
    required String resource,
    required Object id,
    required Map<String, dynamic> data,
  });

  /// Updates an existing resource.
  Future<void> update({
    required String resource,
    required Object id,
    required Map<String, dynamic> data,
  });

  /// Deletes a resource.
  Future<void> delete({
    required String resource,
    required Object id,
  });

  /// Retrieves a resource by its identifier.
  ///
  /// Returns `null` if the resource does not exist.
  Future<Map<String, dynamic>?> get({
    required String resource,
    required Object id,
  });
}
