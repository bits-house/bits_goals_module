# Diff Details

Date : 2026-01-08 17:08:23

Directory c:\\Users\\mathe\\dev\\PROD\\packages\\bits_house\\bits_goals_module\\lib\\src

Total : 31 files,  -871 codes, -68 comments, -211 blanks, all -1150 lines

[Summary](results.md) / [Details](details.md) / [Diff Summary](diff.md) / Diff Details

## Files
| filename | language | code | comment | blank | total |
| :--- | :--- | ---: | ---: | ---: | ---: |
| [lib/src/core/domain/entities/annual\_revenue\_goal.dart](/lib/src/core/domain/entities/annual_revenue_goal.dart) | Dart | 84 | 25 | 26 | 135 |
| [lib/src/core/domain/entities/monthly\_revenue\_goal.dart](/lib/src/core/domain/entities/monthly_revenue_goal.dart) | Dart | 51 | 22 | 18 | 91 |
| [lib/src/core/domain/failures/annual\_revenue\_goal/annual\_revenue\_goal\_failure.dart](/lib/src/core/domain/failures/annual_revenue_goal/annual_revenue_goal_failure.dart) | Dart | 11 | 0 | 5 | 16 |
| [lib/src/core/domain/failures/annual\_revenue\_goal/annual\_revenue\_goal\_failure\_reason.dart](/lib/src/core/domain/failures/annual_revenue_goal/annual_revenue_goal_failure_reason.dart) | Dart | 7 | 5 | 5 | 17 |
| [lib/src/core/domain/failures/failure.dart](/lib/src/core/domain/failures/failure.dart) | Dart | 4 | 0 | 2 | 6 |
| [lib/src/core/domain/failures/money/invalid\_money\_failure.dart](/lib/src/core/domain/failures/money/invalid_money_failure.dart) | Dart | 11 | 0 | 5 | 16 |
| [lib/src/core/domain/failures/money/invalid\_money\_reason.dart](/lib/src/core/domain/failures/money/invalid_money_reason.dart) | Dart | 3 | 2 | 1 | 6 |
| [lib/src/core/domain/failures/month/invalid\_month\_failure.dart](/lib/src/core/domain/failures/month/invalid_month_failure.dart) | Dart | 11 | 0 | 6 | 17 |
| [lib/src/core/domain/failures/month/invalid\_month\_reason.dart](/lib/src/core/domain/failures/month/invalid_month_reason.dart) | Dart | 4 | 2 | 2 | 8 |
| [lib/src/core/domain/failures/monthly\_revenue\_goal/monthly\_revenue\_goal\_failure.dart](/lib/src/core/domain/failures/monthly_revenue_goal/monthly_revenue_goal_failure.dart) | Dart | 10 | 0 | 5 | 15 |
| [lib/src/core/domain/failures/repositories/repository\_failure.dart](/lib/src/core/domain/failures/repositories/repository_failure.dart) | Dart | 16 | 4 | 5 | 25 |
| [lib/src/core/domain/failures/repositories/repository\_failure\_reason.dart](/lib/src/core/domain/failures/repositories/repository_failure_reason.dart) | Dart | 7 | 7 | 2 | 16 |
| [lib/src/core/domain/failures/year/invalid\_year\_failure.dart](/lib/src/core/domain/failures/year/invalid_year_failure.dart) | Dart | 9 | 0 | 4 | 13 |
| [lib/src/core/domain/failures/year/invalid\_year\_reason.dart](/lib/src/core/domain/failures/year/invalid_year_reason.dart) | Dart | 4 | 2 | 2 | 8 |
| [lib/src/core/domain/repositories/yearly\_revenue\_goal\_repository.dart](/lib/src/core/domain/repositories/yearly_revenue_goal_repository.dart) | Dart | 5 | 18 | 2 | 25 |
| [lib/src/core/domain/services/split\_annual\_revenue\_goal.dart](/lib/src/core/domain/services/split_annual_revenue_goal.dart) | Dart | 20 | 14 | 4 | 38 |
| [lib/src/core/domain/value\_objects/money.dart](/lib/src/core/domain/value_objects/money.dart) | Dart | 37 | 34 | 13 | 84 |
| [lib/src/core/domain/value\_objects/month/month.dart](/lib/src/core/domain/value_objects/month/month.dart) | Dart | 25 | 17 | 13 | 55 |
| [lib/src/core/domain/value\_objects/month/month\_name.dart](/lib/src/core/domain/value_objects/month/month_name.dart) | Dart | 14 | 0 | 1 | 15 |
| [lib/src/core/domain/value\_objects/year.dart](/lib/src/core/domain/value_objects/year.dart) | Dart | 19 | 8 | 7 | 34 |
| [lib/src/features/goals\_management/domain/use\_cases/create\_annual\_revenue\_goal/create\_annual\_revenue\_goal.dart](/lib/src/features/goals_management/domain/use_cases/create_annual_revenue_goal/create_annual_revenue_goal.dart) | Dart | 53 | 15 | 12 | 80 |
| [lib/src/features/goals\_management/domain/use\_cases/create\_annual\_revenue\_goal/create\_annual\_revenue\_goal\_params.dart](/lib/src/features/goals_management/domain/use_cases/create_annual_revenue_goal/create_annual_revenue_goal_params.dart) | Dart | 10 | 0 | 3 | 13 |
| [test/bits\_goals\_module\_method\_channel\_test.dart](/test/bits_goals_module_method_channel_test.dart) | Dart | -22 | 0 | -6 | -28 |
| [test/bits\_goals\_module\_test.dart](/test/bits_goals_module_test.dart) | Dart | -23 | 0 | -7 | -30 |
| [test/src/core/domain/entities/annual\_revenue\_goal\_test.dart](/test/src/core/domain/entities/annual_revenue_goal_test.dart) | Dart | -300 | -41 | -67 | -408 |
| [test/src/core/domain/entities/monthly\_revenue\_goal\_test.dart](/test/src/core/domain/entities/monthly_revenue_goal_test.dart) | Dart | -51 | -12 | -15 | -78 |
| [test/src/core/domain/services/split\_annual\_revenue\_goal\_test.dart](/test/src/core/domain/services/split_annual_revenue_goal_test.dart) | Dart | -83 | -19 | -22 | -124 |
| [test/src/core/domain/value\_objects/money\_test.dart](/test/src/core/domain/value_objects/money_test.dart) | Dart | -346 | -48 | -114 | -508 |
| [test/src/core/domain/value\_objects/month/month\_test.dart](/test/src/core/domain/value_objects/month/month_test.dart) | Dart | -162 | -15 | -34 | -211 |
| [test/src/core/domain/value\_objects/year\_test.dart](/test/src/core/domain/value_objects/year_test.dart) | Dart | -77 | -9 | -25 | -111 |
| [test/src/features/goals\_management/domain/use\_cases/create\_annual\_revenue\_goal/create\_annual\_revenue\_goal\_test.dart](/test/src/features/goals_management/domain/use_cases/create_annual_revenue_goal/create_annual_revenue_goal_test.dart) | Dart | -222 | -99 | -64 | -385 |

[Summary](results.md) / [Details](details.md) / [Diff Summary](diff.md) / Diff Details