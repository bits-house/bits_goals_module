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
- Operational KPIs  
- Consistent business rules across multiple apps  

---

## Architecture

This module adopts:

- **Clean Architecture**  
- **MVVM** in the presentation layer  

All major architectural decisions are documented through **Architecture Decision Records (ADR)**.

📌 For full architectural rationale, see:  
**[docs/adr](docs/adr) — Architecture Decision Records (ADR)**

This directory preserves the motivation behind:

- Developing the module as a plugin  
- Dividing the code into Core / Features / Infra  
- Persistence strategies  
- Dependency injection strategy  
- Reuse across plugins and a future Dart backend  

---

## Host Application Integration

This plugin is intentionally **application-agnostic**.

That means:

- No SDK initialization happens inside the plugin  
- All infrastructure configuration must be done in the **host application**  
- All dependencies are **injected from outside**

Examples of host app responsibilities:

- Firestore initialization  
- HTTP client configuration  
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
