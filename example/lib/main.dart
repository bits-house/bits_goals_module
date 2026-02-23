import 'package:bits_goals_module_example/home_page.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:bits_goals_module/bits_goals_module.dart';

void main() {
  final firestore = FakeFirebaseFirestore();
  runApp(
    MyApp(
      config: GoalsModuleConfig(
        remoteDataSrcConfig: FirestoreConfig(
          firestore: firestore,
          annualRevenueGoalsMetaCollectionName: 'annualRevenueGoalsMeta',
          monthlyRevenueGoalsCollectionName: 'monthlyRevenueGoals',
          goalsActionLogsCollectionName: 'goalsActionLogs',
        ),
        getCurrentUser: () => LoggedInUser.create(
          displayName: 'Matheus',
          email: 'matheus@example.com',
          roleName: 'admin',
          uid: 'my-unique-user-id',
        ),
        roles: [
          UserRole(
            roleName: 'admin',
            rolePermissions: const [
              GoalsModulePermission.createAnnualRevenueGoals,
            ],
          ),
        ],
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.config,
  });

  final GoalsModuleConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(config: config),
    );
  }
}
