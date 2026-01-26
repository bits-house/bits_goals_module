import 'package:bits_goals_module/src/infra/config/data_sources/remote_data_src_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Configuration implementation for [RemoteDataSourceConfig] using Firebase Firestore.
///
/// This class centralizes the collection names and the client instance,
/// ensuring the Goals Module accesses the correct database paths.
class FirestoreConfig implements RemoteDataSourceConfig {
  /// Firestore client instance.
  final FirebaseFirestore _firestore;

  /// Name of the collection where monthly revenue goals are stored.
  final String monthlyRevenueGoalsCollection;

  /// Name of the collection containing annual revenue goal metadata.
  final String annualRevenueGoalsMetaCollection;

  /// Name of the collection of action logs, for actions performed on goals module.
  final String goalsActionLogsCollection;

  /// Creates a [FirestoreConfig] instance.
  ///
  /// All collection names must be non-empty strings.
  FirestoreConfig({
    required FirebaseFirestore firestore,
    required String monthlyRevenueGoalsCollectionName,
    required String annualRevenueGoalsMetaCollectionName,
    required String goalsActionLogsCollectionName,
  })  : assert(monthlyRevenueGoalsCollectionName.isNotEmpty,
            'monthlyRevenueGoalsCollectionName cannot be empty'),
        assert(annualRevenueGoalsMetaCollectionName.isNotEmpty,
            'annualRevenueGoalsMetaCollectionName cannot be empty'),
        assert(goalsActionLogsCollectionName.isNotEmpty,
            'goalsActionLogsCollectionName cannot be empty'),
        _firestore = firestore,
        monthlyRevenueGoalsCollection = monthlyRevenueGoalsCollectionName,
        annualRevenueGoalsMetaCollection = annualRevenueGoalsMetaCollectionName,
        goalsActionLogsCollection = goalsActionLogsCollectionName;

  /// Returns the Host app Firestore instance.
  @override
  FirebaseFirestore get client => _firestore;
}
