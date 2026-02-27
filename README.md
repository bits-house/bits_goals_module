# bits_goals_module

> ⚠️ **Project status:**  
> This plugin **does not have a stable release yet** and is in **active development**.

---

## Overview

**bits_goals_module** is a **Flutter Plugin Module** focused on **sales management, revenue goals, and operational metrics**, designed to be reused across multiple applications.

It was created to:

- Fulfill an urgent requirement of an existing application  
- Be reused in a second application planned for the near future  
- Serve as a **showcase module** for a clean and scalable architecture  

The features in this module are common across many management systems, especially in niche business applications that require:

- Sales goals  
- Revenue targets
- Consistent business rules across multiple apps 

> Note: An example app will be developed and released in the future to demonstrate the module's capabilities without needing to integrate it into an existing codebase.

---

## Architecture

This module adopts **Clean Architecture**.

📌 Architectural decisions are documented through **Architecture Decision Records (ADR)**, check: **[docs/architecture/adr](docs/architecture/adr)**

### Main architectural decisions:

Architecture overview:
- **[ADR-0014](docs/architecture/adr/ADR-0014.md)** — Dependency Flow and Layer Import Rules

Use case integration with host applications:
- **[ADR-0017](docs/architecture/adr/ADR-0017.md)** — TransactionRunner for cross-module/app transactional orchestration (integration use cases)

Presentation layer architecture:
- **[ADR-0019](docs/architecture/adr/ADR-0019.md)** — Store-driven Presentation Architecture (non-MVVM)

---

## Host Application Integration

> Note: This section is a **preview** of the integration approach and is still being refined. Detailed instructions will be provided in the future.

This plugin is intentionally **application-agnostic**.

That means:

- No SDK initialization happens inside the plugin  
- All infrastructure configuration must be done in the **host application**  
- All dependencies are **injected from outside**

Examples of host app responsibilities:

- Firestore initialization
- User, roles, and permissions mapping  

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
