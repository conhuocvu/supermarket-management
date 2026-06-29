---
trigger: model_decision
description: Use this rule when generating, modifying, or reviewing Flutter/Dart code, including widgets, layouts, state management, navigation, theming, responsive UI, project structure, and Flutter best practices.
---

# Flutter Development Rules

Canonical UI design source: `design.md`.

This document defines Flutter-specific implementation rules.

All UI decisions (colors, typography, spacing, components, animations) MUST follow `design.md`.

---

# 1. Framework

- Flutter Stable
- Material Design 3
- Dart latest stable version

Do not use deprecated Flutter APIs.

---

# 2. Project Structure

Organize the project as follows:

lib/
    core/
        theme/
        constants/
        utils/

    models/
    services/
    providers/
    widgets/
    screens/

Rules:

- UI belongs in `screens/` and `widgets/`.
- Business logic belongs in `providers/` or `services/`.
- Models only represent data.
- Widgets MUST NOT call APIs directly.

---

# 3. State Management

Use Riverpod.

Rules:

- Keep business logic out of widgets.
- Avoid placing logic inside `build()`.
- Providers manage state.
- Widgets render UI only.

---

# 4. Navigation

Use GoRouter.

- Do not use `Navigator.push()` unless required by GoRouter.
- Define routes centrally.
- Avoid hardcoded route strings.

---

# 5. Networking

Use Dio.

Rules:

- All HTTP requests belong in `services/`.
- Widgets MUST NOT perform networking.
- Never communicate directly with Supabase.
- Spring Boot is the only backend entry point.

---

# 6. Models

- Create strongly typed Dart models.
- Parse JSON using `fromJson()` / `toJson()`.
- Avoid passing raw `Map<String, dynamic>` through the UI.

---

# 7. Screen States

Every asynchronous screen MUST support:

- Loading
- Empty
- Error
- Success

Reuse shared widgets whenever available.

---

# 8. Responsive Layout

Support:

- Android phones
- iPhones
- Tablets

Guidelines:

- Use `LayoutBuilder`, `MediaQuery`, `Expanded`, and `Flexible`.
- Avoid fixed widths unless necessary.
- Prevent overflow on all supported devices.

---

# 9. Performance

- Prefer `const` constructors.
- Use `ListView.builder` for dynamic lists.
- Minimize unnecessary rebuilds.
- Extract reusable widgets instead of deeply nested trees.

---

# 10. Code Style

- Run `dart format` before committing.
- Remove unused imports.
- Remove debug prints before merging.
- Do not leave commented-out or dead code.

---

# 11. Naming Convention

Classes:

- ProductService
- LoginScreen
- ProductCard

Variables:

camelCase

Classes:

PascalCase

Constants:

UPPER_SNAKE_CASE

Files:

snake_case

Examples:

product_service.dart

login_screen.dart

product_card.dart

---

# 12. File Size

Recommended limits:

- Widget: < 200 lines
- Screen: < 300 lines
- Service: < 300 lines

Split files when readability decreases.

---

# 13. Source of Truth

If any implementation conflicts with:

- `design.md`
- `architecture.md`

those documents always take precedence.