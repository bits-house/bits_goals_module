import 'dart:convert';

import 'package:bits_goals_module/strings/gen/goals_module_localizations.dart';
import 'package:bits_goals_module_example/home_page.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:bits_goals_module/bits_goals_module.dart';

const String kAnnualRevenueGoalsMetaCollection = 'annual_revenue_goals_meta';
const String kMonthlyRevenueGoalsCollection = 'monthly_revenue_goals';
const String kGoalsActionLogsCollection = 'goals_action_logs';

void main() {
  final firestore = FakeFirebaseFirestore();

  // For demonstration purposes, we listen to specific collections in the fake Firestore
  // instance and print only that collection's state whenever a change occurs.

  // 1. Define the collections we want to listen to and print when they change.
  const monitoredCollections = [
    kAnnualRevenueGoalsMetaCollection,
    kMonthlyRevenueGoalsCollection,
    kGoalsActionLogsCollection,
  ];

  // 2. Listen to snapshot changes and dump the filtered database state
  for (final collection in monitoredCollections) {
    firestore.collection(collection).snapshots().listen(
      (_) {
        debugPrint('--- Data changed in collection: $collection ---');

        // Get the full dump of the fake Firestore database as a JSON string
        final fullDumpString = firestore.dump();

        try {
          // Convert the JSON string to a Dart Map
          final parsedDump = jsonDecode(fullDumpString) as Map<String, dynamic>;

          // Get only the data for the collection that triggered the listener
          final collectionData = parsedDump[collection];

          // Format the filtered data back to a pretty JSON string (with indentation)
          const encoder = JsonEncoder.withIndent('  ');
          final prettyJson = encoder.convert({collection: collectionData});

          debugPrint(prettyJson);
        } catch (e) {
          debugPrint('Error parsing the dump for collection $collection: $e');
        }
      },
    );
  }

  runApp(
    MyApp(firestoreInstance: firestore),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.firestoreInstance,
  });

  final FakeFirebaseFirestore firestoreInstance;

  @override
  Widget build(BuildContext context) {
    final goalsModuleConfig = GoalsModuleConfig(
      remoteDataSrcConfig: FirestoreConfig(
        firestore: firestoreInstance,
        annualRevenueGoalsMetaCollectionName: kAnnualRevenueGoalsMetaCollection,
        monthlyRevenueGoalsCollectionName: kMonthlyRevenueGoalsCollection,
        goalsActionLogsCollectionName: kGoalsActionLogsCollection,
      ),
      getCurrentUser: () => LoggedInUser.ensureValid(
        displayName: 'Matheus',
        email: 'matheus@example.com',
        roleName: 'admin',
        uid: 'my-unique-user-id',
      ),
      getRoles: () => [
        UserRole(
          roleName: 'admin',
          rolePermissions: const [
            GoalsModulePermission.createAnnualRevenueGoals,
          ],
        ),
      ],
      getCurrency: () => Currency.brl,
    );

    return BitsGoalsModule.init(
      config: goalsModuleConfig,
      child: const MaterialApp(
        localizationsDelegates: [
          ...GoalsModuleLocalizations.localizationsDelegates,
        ],
        supportedLocales: [
          ...GoalsModuleLocalizations.supportedLocales,
        ],
        home: HomePage(),
      ),
    );
  }
}
