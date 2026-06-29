# Debugging Checklist

Use this checklist before concluding that an issue has been resolved.

---

# 1. Reproduce

- Can the issue be reproduced consistently?
- What are the exact reproduction steps?
- Is it device-specific?
- Is it environment-specific?

---

# 2. Logs

Collect:

- Flutter logs
- Spring Boot logs
- HTTP requests
- HTTP responses
- Stack traces
- SQL errors
- Build output

Never ignore warnings that may relate to the issue.

---

# 3. Flutter

Verify:

- Widget rebuilds
- State updates
- Navigation
- Provider/Riverpod state
- Theme
- Layout constraints
- Async code
- Null safety
- Memory leaks

Common issues:

- setState after dispose
- Widget overflow
- Missing await
- Infinite rebuilds
- Context misuse

---

# 4. Backend

Verify:

- Controller mapping
- Service logic
- Repository queries
- Validation
- Exception handling
- Dependency Injection
- Security filters
- JWT
- Transactions

Common issues:

- NullPointerException
- Bean injection failure
- Incorrect transaction scope
- Validation missing
- Wrong HTTP status

---

# 5. API

Verify:

- Base URL
- Endpoint path
- HTTP method
- Request body
- Response body
- Authentication header
- Authorization
- CORS
- Serialization

Common issues:

- 400 Bad Request
- 401 Unauthorized
- 403 Forbidden
- 404 Not Found
- 500 Internal Server Error

---

# 6. Database

Verify:

- Connection
- Foreign keys
- Constraints
- Duplicate data
- Missing data
- Transactions
- SQL execution

Common issues:

- Constraint violation
- Missing migration
- Incorrect relationship
- Data inconsistency

---

# 7. Configuration

Verify:

- .env
- application.properties
- API URL
- JWT Secret
- Database URL
- Ports
- Build profiles

---

# 8. Performance

Check:

- Duplicate API requests
- Multiple widget rebuilds
- Slow SQL queries
- Large object allocations
- Blocking operations
- Infinite loops

---

# 9. Regression

After applying a fix:

- Reproduce the original scenario.
- Test related features.
- Verify no new warnings appear.
- Confirm logs are clean.
- Verify expected behavior on both frontend and backend.

---

# 10. Before Closing

Confirm:

- Root cause identified
- Fix verified
- Side effects evaluated
- Architecture preserved
- Coding standards maintained
- No temporary hacks introduced