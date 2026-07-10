---
name: implement-screen
description: Create or rebuild a Flutter screen following the project's architecture, Viridian Ops design system, and coding standards. Use whenever creating new UI screens, CRUD pages, dashboards, or settings.
---

# Implement Screen

## Purpose

Create a new Flutter screen that follows the project's architecture, design system, and coding standards.

## When to use

Use this skill when:

- Creating a new screen
- Rebuilding an existing screen
- Implementing a UI from Figma or Stitch
- Creating CRUD pages
- Creating dashboards
- Creating settings pages

## Inputs

- Screen requirements
- UI mockup (optional)
- Existing API (optional)

## Output

The generated screen should include:

- Screen widget
- Responsive layout
- Loading state
- Empty state
- Error state
- Success state
- Proper navigation
- Theme support
- Shared components only
- **Database Alignment**: Always check Supabase/PostgreSQL schema (`update_schema.sql` or DB directly) for missing columns or tables needed by the screen. If missing, add them to the entity and append the `ALTER TABLE` to `database/update_schema.sql`.

## Screen UI Patterns (List & Form)

When designing screens for this project (especially List or Form/Add/Edit screens), you MUST follow these patterns extracted from existing screens (e.g., Product and Category Management):

### 1. App Shell & Title (Navigation)
- **Do NOT** use a standard `AppBar` inside the screen body.
- Use `WidgetsBinding.instance.addPostFrameCallback` inside `initState` to update the global app shell title and breadcrumbs via `shellLayoutProvider`.
- Example: `ref.read(shellLayoutProvider.notifier).update(title: 'Category Management', breadcrumbs: ['Inventory', 'Categories']);`

### 2. Form Screens (Add/Edit)
- **No Inner Title Text**: Do not put the title text ("Add Product", "Edit Category") in the screen body since it is already on the top breadcrumbs.
- **Back Button**: Place a back button at the very top left of the form content:
  `IconButton(icon: Icon(Icons.arrow_back), style: IconButton.styleFrom(backgroundColor: theme.colorScheme.surfaceContainerHighest), onPressed: () => context.pop(false))`
- **Form Container**: Wrap the actual form fields inside a `Container` with:
  - White background (`theme.colorScheme.surface`)
  - Padding `24px`, Border Radius `16px`
  - Subtle border: `Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5))`
  - Drop shadow: `BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 2))`
- **Input Fields Decoration**: All TextFormFields/Dropdowns MUST have a uniform format:
  - `filled: true`
  - `fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)`
  - Border radius `16px` for normal, focused, and error borders.

### 3. List Screens (Data Tables)
- Wrap the main table in an `Expanded` `Card` with `elevation: 2`, `shadowColor: Colors.black.withOpacity(0.04)`, and rounded border `16px`.
- In the table header/filter area, include a Search field and an "Add [Entity]" FilledButton.
- For inactive items, fade out the text color and background color of the row slightly to distinguish them from active items.

## Follow

- design.md
- flutter.md
- architecture.md
- components.md
- error-handling.md

Before finishing, verify the checklist in `references/screen-checklist.md`.