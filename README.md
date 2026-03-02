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

> Note: A standalone example app will be released in the future to demonstrate the module’s capabilities without needing integration into an existing codebase.

---

## Host Application Integration

This plugin is intentionally **application-agnostic**.

That means:

- No SDK initialization happens inside the plugin
- All dependencies are **injected from the host application**

## 1) Initialize the module in your app

Initializing the module in your Flutter App is as simple as wrapping it with `BitsGoalsModule.init`, providing the `config`. Example:

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

> Note: You can wrap any widget with `BitsGoalsModule.init`, it doesn't have to be the root of your app. The features will be available throughout the widget tree (only within the subtree of the wrapped widget). You can also wrap it in another module if you want to integrate multiple modules together. `GoalsModuleLocalizations` can be used independently of the `BitsGoalsModule` initialization.

The `config` is a required parameter that provides the necessary configuration for the module to function properly. It requires only 4 things: `remoteDataSrcConfig`, `getCurrentUser`, `getRoles`, and `getCurrency`. Example:

```dart
final goalsModuleConfig = GoalsModuleConfig(
      // 1) [remoteDataSrcConfig]
      // In this case it uses [FirestoreConfig] for Firestore integration.
      // You need to provide the Firestore instance already initialized by your app, 
      // and the collection names to be used by the module for storing the goals data 
      // and logs. (must not conflict with your app's existing collections)
      remoteDataSrcConfig: FirestoreConfig(
        firestore: firestoreInstance, // <-- Provide your Firestore instance here
        monthlyRevenueGoalsCollectionName: 'monthly_revenue_goals',
        goalsActionLogsCollectionName: 'goals_action_logs',
        // ... other collection names
      ),
      // 2) [getCurrentUser]
      // This is a callback function that the module will call whenever it 
      // needs to know the current logged in user. You should implement it 
      // according to your app's authentication logic.
      // You MUST return a [LoggedInUser], which is the representation of the user.
      // So the module can enforce access control, logs and other features based on 
      // the user's identity, role and permissions.
      getCurrentUser: () { 
        try {
          return LoggedInUser.ensureValid(
            displayName: 'Matheus',
            email: 'matheus@example.com',
            roleName: 'admin',
            uid: 'my-unique-user-id',
          );
        } catch (e) {
          // Handle the exception appropriately
        }
      },
      // 3) [getRoles]
      // This is a callback function returning a list of [UserRole].
      // You should define roles and permissions according to your app's needs,
      // mapping your application's roles to the module's feature permissions.
      getRoles: () => [
        UserRole(
          roleName: 'admin',
          rolePermissions: const [
            GoalsModulePermission.createAnnualRevenueGoals,
            // Add other permissions for this role as needed
          ],
        ),
        // Add other roles as needed
      ],
      // 4) [getCurrency]
      // This is a callback function that the module will call whenever it needs to
      // get the currency to be used in the goals management features. You can implement
      // it according to your app's logic, for example, returning the currency based on
      // the user's locale, or a default currency for your app.
      getCurrency: () => Currency.fromISO4217('BRL');
    );
```

## ⚠️ Warnings
- Permissions are only enforced by the UI components and use cases provided by this module. You MUST configure your backend to enforce the same permissions to ensure data integrity and security (e.g., Firestore Security Rules).

- These callbacks may throw runtime exceptions due to internal (domain) validations that ensure the provided data is consistent and valid. They are invoked by the module at runtime — if an invalid value is returned and not properly handled, it may cause your application to crash.

- If your callbacks return only hardcoded values, exception handling is not strictly required. However, you must ensure those values are correct, tested, and domain-valid.

> Note: You can implement custom access control logic based on the user's state or other application-specific factors. The module invokes the provided callbacks whenever it needs to verify a permission, allowing you to support dynamic permissions without hardcoding them in the `getRoles` configuration.

> Tip: If your application does not have a role and permission management system, you can create a single role with all `GoalsModulePermission` permissions and assign it to every user.

> Note: If your backend is not yet supported by the module, you can add support by implementing the `RemoteDataSourceConfig` interface and creating the required data sources according to its contract (all the required implementation is centralized in the infra layer folder, no need to touch other parts of the module).

> Tip: Although this module is initialized via a widget wrapper, its `config` callbacks can be implemented in architectural layers outside of the presentation.

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

> Note: Some features, like updating goals based on orders updates, might require additional configuration, such as setting up a `TransactionRunner` to ensure data consistency and atomicity between operations in the host application and this module. Check the documentation and the usage example for more details: **[TransactionRunner](lib/src/core/application/ports/transaction/transaction_runner.dart)**

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
