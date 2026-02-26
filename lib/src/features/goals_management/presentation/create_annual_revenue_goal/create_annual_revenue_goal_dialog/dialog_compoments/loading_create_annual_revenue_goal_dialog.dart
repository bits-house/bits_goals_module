import 'package:flutter/material.dart';

class LoadingCreateAnnualRevenueGoalDialog extends StatelessWidget {
  const LoadingCreateAnnualRevenueGoalDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(64),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
        ],
      ),
    );
  }
}
