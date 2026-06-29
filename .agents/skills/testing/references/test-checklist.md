# Testing Checklist

Use this checklist before considering a feature fully tested.

---

# 1. Requirements

- Business requirement understood
- Expected behavior defined
- Acceptance criteria identified

---

# 2. Unit Tests

Verify:

- Business logic
- Validation
- Utility methods
- Data transformations
- Calculations

Checklist:

- Happy path
- Invalid input
- Boundary values
- Exception handling

---

# 3. Widget Tests

Verify:

- Rendering
- User interaction
- Form validation
- Navigation
- Loading state
- Empty state
- Error state

Common issues:

- Missing validation
- Incorrect rebuild
- Broken navigation
- Widget overflow

---

# 4. API Tests

Verify:

- Correct endpoint
- HTTP method
- Headers
- Authentication
- Authorization
- Request body
- Response body
- Status codes

Common responses:

- 200 OK
- 201 Created
- 400 Bad Request
- 401 Unauthorized
- 403 Forbidden
- 404 Not Found
- 500 Internal Server Error

---

# 5. Backend Tests

Verify:

- Controller mapping
- Service logic
- Validation
- Exception handling
- Transactions
- Repository queries

Common issues:

- Missing validation
- Wrong status codes
- Incorrect transaction scope
- Missing security checks

---

# 6. Database

Verify:

- Constraints
- Foreign keys
- Transactions
- Data consistency
- Duplicate handling

---

# 7. Security

Verify:

- Authentication required
- Authorization enforced
- Sensitive data protected
- Invalid tokens rejected

---

# 8. Performance

Verify:

- Large datasets
- Pagination
- Slow network
- Concurrent requests

Avoid unnecessary API calls.

---

# 9. Regression

After every bug fix:

- Original issue no longer occurs
- Related features still work
- Existing tests continue to pass
- No unintended side effects

---

# 10. Before Completion

Confirm:

- Business requirements covered
- Success scenarios tested
- Failure scenarios tested
- Edge cases tested
- Security considered
- Performance considered
- Regression risks evaluated
- Tests remain readable and maintainable