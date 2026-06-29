# Review Checklist

## Architecture

- Controller contains no business logic
- Services are cohesive
- Repository only accesses database
- Flutter widgets do not call APIs directly
- Proper separation of concerns

---

## Flutter

- No hardcoded colors
- Uses ThemeData
- Uses shared components
- Responsive
- No widget overflow
- Uses const constructors
- Uses ListView.builder when appropriate
- No duplicated widgets

---

## Backend

- Proper exception handling
- Uses DTOs
- No Entity returned directly
- Validation exists
- Transactions where required
- REST conventions followed

---

## API

- Correct HTTP methods
- Correct status codes
- Consistent response format
- JWT protected endpoints
- Input validation

---

## Database

- Avoid N+1 queries
- Proper indexing where needed
- No duplicated queries
- Transactions used correctly

---

## Security

- No secrets committed
- Passwords hashed
- JWT handled securely
- Authorization verified
- SQL Injection prevention

---

## Error Handling

- No empty catch blocks
- No raw exceptions shown
- User-friendly messages
- Retry only when appropriate

---

## Performance

- No unnecessary rebuilds
- Avoid duplicated API calls
- Avoid unnecessary allocations
- Lazy loading where appropriate

---

## Code Quality

- Clear naming
- Small functions
- Small classes
- No dead code
- No commented-out code
- Proper formatting

---

## UI

- Matches design.md
- Proper spacing
- Proper typography
- Proper component usage
- Consistent interaction