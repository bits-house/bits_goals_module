# bits_goals_module

> ⚠️ **Project status:**  
> This plugin **does not have a stable release yet** and is in **active development**.

---

## Overview

**bits_goals_module** is a reusable **Flutter plugin** module that implements **sales and revenue goals management** features, designed for integration across multiple applications.

It was created to:

- Fulfill an urgent requirement of an existing application  
- Be reused in a second application planned for the near future  
- Serve as a **showcase module** for a clean and scalable architecture  

> Note: An example app will be developed and released in the future to demonstrate the module's capabilities without needing to integrate it into an existing codebase, as well as provide a list of all the features implemented in the module and how to use them.

---

## Host Application Integration

This plugin is intentionally **application-agnostic**.

That means:

- No SDK initialization happens inside the plugin
- All dependencies are **injected from the host application**

## 1) Initialize the module in your app

Initializing the Goals module in your Flutter App is as simple as wrapping it with `BitsGoalsModule.init`, providing the `config`. Example:

```dart
return BitsGoalsModule.init(
      config: goalsModuleConfig,
      child: const MaterialApp(
        home: HomePage(),
      ),
    );
```

In order for the localization strings provided by the module to work, you need to include the `localizationsDelegates` and `supportedLocales` in your `MaterialApp`:

```dart
return BitsGoalsModule.init(
      config: goalsModuleConfig,
      child: const MaterialApp(
        localizationsDelegates: [
          ...GoalsModuleLocalizations.localizationsDelegates, // <-- Add this
          // ... your app's other localization delegates
        ],
        supportedLocales: [
          ...GoalsModuleLocalizations.supportedLocales, // <-- And this
          // ... your app's other supported locales
        ],
        home: HomePage(),
      ),
    );
```

> Note: You can wrap any widget with `BitsGoalsModule.init`, it doesn't have to be the root of your app. You can also wrap it in another module if you want to integrate multiple modules together. `GoalsModuleLocalizations` is independent of the `BitsGoalsModule` initialization.

The `config` is a required parameter that provides the necessary configuration for the module to function properly. It requires only 3 things: `remoteDataSrcConfig`, `getCurrentUser`, and `getRoles`. Example:

```dart
final goalsModuleConfig = GoalsModuleConfig(
      // 1) [remoteDataSrcConfig]
      // In this case it uses [FirestoreConfig] for Firestore integration.
      // You need to provide the Firestore instance already initialized by your app, 
      // and the collection names to be used by the module for storing 
      // the goals data and logs. (must not conflict with your app's existing collections)
      remoteDataSrcConfig: FirestoreConfig(
        firestore: firestoreInstance, // <-- Provide your Firestore instance here
        monthlyRevenueGoalsCollectionName: 'monthly_revenue_goals',
        goalsActionLogsCollectionName: 'goals_action_logs',
        // ... other collection names
      ),
      // 2) [getCurrentUser]
      // This is a callback function that the module will call
      // whenever it needs to know the current logged in user.
      // You should implement it according to your app's authentication logic.
      // You MUST return a [LoggedInUser], which is the representation of the user.
      // So the module can enforce access control, logs and other features based on 
      // the user's identity, role and permissions.
      getCurrentUser: () => LoggedInUser.create(
        displayName: 'Matheus',
        email: 'matheus@example.com',
        roleName: 'admin',
        uid: 'my-unique-user-id',
      ),
      // 3) [getRoles]
      // This is a callback function that returns a list of [UserRole].
      // You should define the roles and permissions according to your app's needs,
      // mapping your app's specific roles to the module's features permissions.
      getRoles: () => [
        UserRole(
          roleName: 'admin',
          rolePermissions: const [
            GoalsModulePermission.createAnnualRevenueGoals,
            // ... add other permissions for the role as needed
          ],
        ),
        // ... add other roles as needed
      ],
    );
```

> Note: You can implement custom access control logic based on the user's state or other factors in your app. The module will call the callback functions every time it needs to check if the user has a specific permission, allowing you to implement dynamic permissions that can change based on the user's state or other factors in your app, without needing to hardcode it in the `getRoles` configuration.

> `WARNING`: The permissions are only verified on the UI components and Use Cases provided by this Module. You MUST configure your backend to enforce the same permissions, ensuring data integrity and security.

> Tip: If your app doesn't have a role and permission management system, you can just create a single role with all `GoalsModulePermission` and assign it to every user as their `roleName`.

> Note: You can easily swipe between backends/databases (even different types) only by swapping the `remoteDataSrcConfig`. If your backend is not supported by the module yet, you can do so by implementing the `RemoteDataSourceConfig` interface, and then implementing the necessary data sources following the interface's contract (all that is centralized in the infra layer folder, no need to touch other parts of the module).

And that's it! The module is now ready to be used in your app.

## 2) Use the module's features in your app

After initializing the module, you can start using its features in your app. The module provides a set of pre-built UI components and use cases that you can use directly in your app. 

Example, creating an annual revenue goal:

```dart
class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals Module Example'),
      ),
      // Add the Create Annual Revenue Goal button:
      floatingActionButton: CreateAnnualRevenueGoalButton.fabLarge(), // <-- Just add this
      // This button is only visible to users with the permission to create annual 
      // revenue goals.
      // It will call the use case to create an annual revenue goal and show the pre-built 
      // UI for that feature when pressed, handling all the logic, validations, 
      // states, errors, and data persistence using the provided data source in the 
      // configuration for you. No other implementation needed for this feature.
    );
  }
}

```

> Note: Some features, like updating goals based on orders updates, might require additional configuration, such as setting up a `TransactionRunner` to ensure data consistency and atomicity between operations in the Host application and the module. Check the documentation and the usage example for more details: **[TransactionRunner](lib/src/core/application/ports/transaction/transaction_runner.dart)**

---

## Themes And Customization

The Module widget's UI uses Flutter Material 3 components and follows Material 3 design guidelines by default. It will automatically adapt to the host application's theme, including colors, typography, and other visual properties defined in the host application's `ThemeData`, like shapes and elevations. Furthermore, the module provides some customization options in specific components. For example, the `CreateAnnualRevenueGoalButton` allows you to choose between different button styles (like FAB and FilledButton) and directly customize colors and icon properties.

> Tip: If you need to implement a custom design that is not supported by the module's built-in customization options, you can create your own UI and call the module's use cases directly to handle the logic and data management. This way, you can have a fully custom UI while still leveraging the module's features and business logic.

---

## Architecture

This module adopts `Clean Architecture`.

📌 Architectural decisions are documented through **Architecture Decision Records (ADR)**, check: **[docs/architecture/adr](docs/architecture/adr)**

#### Main architectural decisions:

- **[ADR-0014](docs/architecture/adr/ADR-0014.md)** (Module architecture overview)

    > Example Use Case implementation adhering to the architecture:
    > - **[Use Case - Create Annual Revenue Goal](lib/src/features/goals_management/application/use_cases/create_annual_revenue_goal/create_annual_revenue_goal.dart)**

- **[ADR-0017](docs/architecture/adr/ADR-0017.md)** (Use case integration with host applications)

- **[ADR-0019](docs/architecture/adr/ADR-0019.md)** (Presentation layer architecture)

    > Examples adhering to the Store-driven Presentation Architecture:
    > - **[Flutter UI - Create Annual Revenue Goal](lib/src/features/goals_management/presentation/create_annual_revenue_goal/create_dialog/create_annual_revenue_goal_dialog.dart)**
    > - **[Store - Create Annual Revenue Goal](lib/src/features/goals_management/presentation/create_annual_revenue_goal/create_dialog/create_annual_revenue_goal_dialog_store.dart)**

---

## Long-Term Vision

This module is part of a broader vision:

- Build a **shared core** reused by multiple Flutter plugins  
- Reuse the same domain logic in a future **Dart backend**  

Guarantee:

- Consistent business rules  
- Low coupling  
- High testability  
- Safe long-term evolution  

---

## Author

Made by [Matheus Grossi](https://github.com/matheusgrossi7)

---

## License

This project is licensed under the **Apache License 2.0**.  
See the [LICENSE](LICENSE) file for details.
