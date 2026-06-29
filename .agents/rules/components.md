---
trigger: model_decision
description: Use this rule when creating or modifying reusable UI components, screens, forms, dialogs, cards, buttons, inputs, tables, loading states, or other shared Flutter widgets.
---

# Shared Components

This document defines the reusable UI components for the Supermarket Management System.

Before creating a new widget, ALWAYS check whether an existing component can be reused.

Do not duplicate UI components.

---

# General Rules

- Reuse existing widgets whenever possible.
- Extend an existing component before creating a new one.
- Components should be generic and reusable.
- Avoid embedding business logic inside reusable widgets.
- Components must follow `design.md`.

---

# Buttons

Use shared button components.

## AppButton

Primary action.

Examples

- Login
- Save
- Create
- Checkout

---

## AppOutlinedButton

Secondary action.

Examples

- Cancel
- Edit
- View Details

---

## AppTextButton

Low emphasis action.

Examples

- Forgot Password
- Learn More

---

## AppIconButton

Icon-only actions.

Requirements

- Tooltip if the meaning is not obvious.
- Minimum touch target: 48dp.

---

# Inputs

## AppTextField

Default text input.

Supports

- label
- hint
- validator
- prefix icon
- suffix icon
- helper text
- error text

Use for

- Name
- Email
- Product
- Search
- Quantity

---

## AppSearchField

Dedicated search component.

Supports

- search icon
- clear button
- debounce (optional)

---

# Cards

## AppCard

Generic card.

Use for

- Forms
- Sections
- Containers

---

## ProductCard

Displays

- Image
- Name
- Price
- Category
- Stock

---

## StatisticCard

Displays

- Icon
- Title
- Value
- Optional trend

Examples

Today's Sales

Inventory

Orders

Revenue

---

# Status

## StatusChip

Supported status

- Success
- Warning
- Error
- Info
- Pending

Status MUST NOT rely on color alone.

Include text.

---

# Loading

## LoadingView

Used for

- Full-screen loading
- Page loading

---

## LoadingIndicator

Small inline loading indicator.

---

# Empty State

## EmptyView

Displays

- Illustration or icon
- Title
- Description
- Optional action button

Example

"No products found."

---

# Error State

## ErrorView

Displays

- Error icon
- Title
- Description
- Retry button

Never display raw exceptions.

---

# Dialogs

## AppDialog

Standard dialog.

Supports

- title
- message
- actions

---

## ConfirmDialog

Confirmation dialog.

Examples

- Delete product
- Logout
- Cancel order

---

# Snackbar

## AppSnackbar

Variants

- Success
- Warning
- Error
- Info

Do not call ScaffoldMessenger directly from screens.

---

# Navigation

## AppScaffold

Provides

- AppBar
- Drawer
- Bottom Navigation
- Floating Action Button
- Safe Area

Every screen SHOULD use AppScaffold.

---

## AppDrawer

Application navigation.

---

## BottomNavigation

Customer navigation.

Maximum

4 destinations.

---

# Tables

## AppDataTable

Supports

- Sorting
- Pagination
- Empty state
- Loading state

Use for

- Inventory
- Orders
- Employees

---

# Lists

## ProductListTile

Compact product display.

---

## OrderListTile

Order summary.

---

## CustomerListTile

Customer summary.

---

# Images

## AppNetworkImage

Supports

- Placeholder
- Loading
- Error image

Do not use Image.network directly.

---

# Avatar

## UserAvatar

Displays

- Profile image
- Initials fallback

---

# Forms

## FormSection

Groups related form fields.

---

# Layout

## PageContainer

Provides

- Responsive padding
- Maximum content width

---

## SectionHeader

Displays

- Title
- Subtitle
- Optional action

---

# Reuse Policy

Before creating any widget, ask:

1. Can an existing component be reused?

2. Can an existing component be extended?

Only create a new component if neither option is suitable.

---

# Source of Truth

All shared components defined here should be reused consistently across the project.

If a reusable component already exists, the AI MUST use it instead of creating a new implementation.