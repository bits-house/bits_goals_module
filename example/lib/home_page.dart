import 'package:bits_goals_module/bits_goals_module.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.config,
  });

  final GoalsModuleConfig config;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals Module Example'),
      ),
      floatingActionButton: CreateAnnualRevenueGoalButton.fabLarge(
        config: config,
      ),
    );
  }
}
