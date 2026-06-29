---
name: testing
description: Design, generate, review, and improve automated tests for the Supermarket Management System. Use whenever adding new features, fixing bugs, refactoring code, or reviewing project quality. Ensure tests validate business behavior, edge cases, security, and regressions rather than implementation details.
---

# Testing

Treat tests as executable specifications of business requirements.

Tests should verify what the system is expected to do, not how it is implemented.

Prefer maintainable, deterministic, and independent tests.

---

## Understand The Feature

Before writing tests:

1. Identify the business requirement.
2. Determine expected behavior.
3. Identify possible failure scenarios.
4. Identify edge cases.
5. Understand dependencies.
6. Define the expected outcome.

Never write tests without understanding the feature.

---

## Determine Test Scope

Choose the appropriate testing level.

### Unit Test

Test:

- Business logic
- Validation
- Utility classes
- Calculations
- Data transformations

Avoid external dependencies.

---

### Widget Test

Test:

- Widget rendering
- User interactions
- Form validation
- Navigation
- Loading state
- Empty state
- Error state

Mock external services whenever possible.

---

### Integration Test

Test interactions between:

- Flutter ↔ Spring Boot
- Controller ↔ Service
- Service ↔ Repository

Verify components work together correctly.

---

### API Test

Verify:

- Request validation
- Response body
- HTTP status codes
- Authentication
- Authorization
- Error responses

---

## Test Design

Every feature should include:

- Happy path
- Invalid input
- Boundary values
- Edge cases
- Failure scenarios
- Regression cases

Do not stop after testing only the happy path.

---

## Flutter Testing

Verify:

- Widget tree
- User interaction
- State updates
- Navigation
- Responsive layout
- Theme compatibility

Avoid testing Flutter framework internals.

---

## Spring Boot Testing

Verify:

- Service logic
- Validation
- Exception handling
- Security
- Repository queries
- Transactions

Business rules should be tested at the Service layer.

---

## API Verification

Verify:

- Correct endpoint
- HTTP method
- Headers
- Request body
- Response body
- Status codes
- Error handling
- Authentication
- Authorization

---

## Test Quality

Every test should be:

- Independent
- Deterministic
- Readable
- Fast
- Repeatable

Avoid flaky tests.

---

## Coverage Strategy

Prioritize testing:

1. Business logic
2. Authentication
3. Inventory operations
4. Order processing
5. Payment-related logic
6. Database transactions

Do not chase 100% code coverage at the expense of meaningful tests.

---

## Never Do

Never:

- Test framework internals
- Duplicate production logic
- Depend on execution order
- Depend on shared mutable state
- Ignore edge cases
- Write meaningless assertions
- Skip regression testing after bug fixes

---

## Expected Output

Every testing task should provide:

1. Test Scope
2. Test Scenarios
3. Test Cases
4. Required Mocks
5. Expected Results
6. Edge Cases
7. Regression Risks

Follow all project rules before generating tests.