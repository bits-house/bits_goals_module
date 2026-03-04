import 'package:bits_goals_module/strings/gen/goals_module_localizations.dart';
import 'package:bits_goals_module_example/home_page.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:bits_goals_module/bits_goals_module.dart';

void main() {
  final firestore = FakeFirebaseFirestore();
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
        annualRevenueGoalsMetaCollectionName: 'annual_revenue_goals_meta',
        monthlyRevenueGoalsCollectionName: 'monthly_revenue_goals',
        goalsActionLogsCollectionName: 'goals_action_logs',
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
