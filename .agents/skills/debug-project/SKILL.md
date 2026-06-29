---
name: debug-project
description: Diagnose and resolve issues across the Supermarket Management System. Use whenever Flutter, Spring Boot, REST APIs, PostgreSQL, authentication, networking, state management, or project configuration behaves unexpectedly. Always identify the root cause before proposing a solution.
---

# Debug Project

Treat every issue as a symptom of an underlying problem.

Never patch symptoms without understanding why the issue occurs.

The objective is to restore correct behavior while preserving the project's architecture, coding standards, and business rules.

---

## Inspect The Problem

1. Read the complete error message before making assumptions.
2. Reproduce the issue whenever possible.
3. Identify which layer is responsible.

Possible layers include:

- Flutter UI
- State Management
- Navigation
- REST API
- Spring Boot
- Business Logic
- Authentication / Authorization
- Database
- Environment Configuration
- Build System
- Dependencies

4. Collect logs, stack traces, request payloads, and responses.
5. Verify the issue before attempting a fix.

Never diagnose solely from screenshots when source code or logs are available.

---

## Trace The Execution Flow

Always trace the complete execution path.

Example

User Action

↓

Flutter Screen

↓

Service

↓

HTTP Request

↓

Spring Controller

↓

Service

↓

Repository

↓

Database

↓

Response

↓

Flutter UI

Locate the first point where actual behavior differs from expected behavior.

---

## Verify Assumptions

Before suggesting any change, verify:

- Environment variables
- Configuration files
- Dependencies
- API endpoints
- Request payloads
- Response payloads
- Authentication state
- Database contents

Do not assume configuration is correct.

---

## Investigate Each Layer

### Flutter

Inspect:

- Widget rebuilds
- State Management
- Async operations
- Navigation
- Theme usage
- Layout constraints
- Null safety
- Memory leaks
- Widget lifecycle
- Performance

---

### Spring Boot

Inspect:

- Controllers
- Services
- Repositories
- DTO mapping
- Bean Validation
- Exception handling
- Dependency Injection
- Transactions
- Security configuration
- JWT processing

Business logic must remain inside the Service layer.

---

### REST API

Verify:

- Endpoint
- HTTP method
- Headers
- Authentication
- Authorization
- Status code
- Request body
- Response body
- JSON serialization
- CORS configuration

---

### Database

Verify:

- Connection
- Constraints
- Foreign Keys
- Missing records
- Duplicate data
- Transactions
- SQL execution
- Data consistency

---

### Environment

Verify:

- .env
- application.properties
- API Base URL
- JWT Secret
- Database configuration
- Supabase configuration
- Build configuration

Incorrect configuration should be ruled out before changing code.

---

## Root Cause Analysis

Every recommendation must explain:

- What failed
- Why it failed
- Why the proposed solution fixes it
- Potential side effects
- Verification steps

Never recommend temporary fixes without explaining the underlying cause.

---

## Fix Strategy

Prefer:

- Smallest safe change
- Existing architecture
- Existing shared components
- Existing coding conventions

Avoid unnecessary refactoring while debugging.

---

## Never Do

Never:

- Ignore stack traces
- Suppress exceptions
- Disable validation
- Disable authentication
- Hardcode values
- Remove business rules
- Modify unrelated files
- Guess the solution without evidence

---

## Expected Output

Every debugging report should contain:

1. Problem Summary
2. Root Cause
3. Evidence
4. Severity
5. Recommended Fix
6. Verification Steps
7. Possible Side Effects

Follow all project rules before proposing code changes.