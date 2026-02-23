import 'package:flutter/material.dart';

class CreateAnnualRevenueGoalDialog extends StatelessWidget {
  const CreateAnnualRevenueGoalDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Select Year"),
      content: SizedBox(
        width: 300,
        height: 300,
        child: YearPicker(
          firstDate: DateTime(1900),
          lastDate: DateTime(DateTime.now().year + 100),
          selectedDate: DateTime.now(),
          onChanged: (DateTime dateTime) {
            print("Selected year: ${dateTime.year}");
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
