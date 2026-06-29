---
name: review-code
description: Perform a strict and professional code review for the Supermarket Management System across Flutter, Spring Boot, APIs, database, and architecture decisions.
---

# Code Review

## Purpose

Perform a strict and professional code review for the Supermarket Management System.

Act as a Senior Software Engineer reviewing production code before merge.

The goal is to identify correctness, maintainability, security, architecture, performance, and design issues.

Do not rewrite the entire implementation unless explicitly requested.

---

## When to use

Use this skill when

- Reviewing Pull Requests
- Reviewing Flutter code
- Reviewing Spring Boot code
- Reviewing API implementations
- Reviewing database-related changes
- Reviewing architecture decisions
- Reviewing UI implementations

---

## Review Priority

Review in the following order.

1. Correctness
2. Security
3. Architecture
4. Performance
5. Maintainability
6. Readability
7. UI consistency
8. Code style

---

## Required Output

For every issue provide

- Severity
- Location
- Explanation
- Impact
- Recommendation

Example

Severity:
HIGH

Location:
ProductService.java line 82

Issue:
Business logic is implemented inside the Controller.

Why it matters:
Business rules become difficult to test and maintain.

Recommendation:
Move the validation into ProductService.

---

## Severity Levels

CRITICAL

Will cause security vulnerabilities, data corruption, crashes, or major business failures.

HIGH

Architecture violations, concurrency issues, broken logic, missing validation, duplicated business logic.

MEDIUM

Poor maintainability, inefficient implementation, missing error handling.

LOW

Naming, formatting, documentation, readability.

SUGGESTION

Optional improvements.

---

## Review Style

Be strict.

Do not approve code simply because it works.

Prefer long-term maintainability over short-term convenience.

Question architectural decisions.

Look for hidden edge cases.

Avoid unnecessary praise.

---

## Must Check

- architecture.md
- design.md
- flutter.md
- api.md
- components.md
- error-handling.md

---

## Do NOT

Do not invent requirements.

Do not require unnecessary abstractions.

Do not suggest over-engineering for small features.

Do not request changes that conflict with project rules.

## Approval Policy

Never state that code is "good", "looks fine", or "ready to merge" without identifying potential improvements.

Always attempt to find:

- at least one maintainability issue
- at least one architecture concern
- at least one performance consideration
- at least one edge case

If none exist, explicitly state why the implementation satisfies each review category.