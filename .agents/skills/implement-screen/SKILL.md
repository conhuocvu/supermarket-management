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

## Follow

- design.md
- flutter.md
- architecture.md
- components.md
- error-handling.md

Before finishing, verify the checklist in `references/screen-checklist.md`.