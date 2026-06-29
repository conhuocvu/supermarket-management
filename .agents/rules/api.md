---
trigger: model_decision
description: Use this rule when implementing or consuming REST APIs, creating Spring Boot controllers, services, DTOs, authentication, request validation, HTTP responses, or Flutter API services.
---

# API Development Rules

This document defines the API communication rules between Flutter and Spring Boot.

All API interactions MUST follow these rules.

---

# 1. General Principles

- Flutter communicates only with Spring Boot.
- Spring Boot is the only backend entry point.
- Flutter MUST NOT access Supabase directly.
- All communication uses HTTPS in production.
- APIs should follow REST principles.

---

# 2. Endpoint Convention

Use plural nouns.

Examples

GET    /api/products

GET    /api/products/{id}

POST   /api/products

PUT    /api/products/{id}

DELETE /api/products/{id}

Nested resources

GET /api/orders/{id}/items

Avoid verbs in URLs.

Correct

/api/products

Wrong

/api/getProducts

---

# 3. HTTP Methods

GET

Retrieve data.

POST

Create data.

PUT

Replace existing data.

PATCH

Update partial data when appropriate.

DELETE

Delete data.

---

# 4. Request Validation

Backend MUST validate

- Required fields
- Data types
- Business rules
- User permissions

Never trust client input.

---

# 5. Response Format

Every response should follow a consistent structure.

Success

```json
{
    "success": true,
    "message": "Operation completed successfully.",
    "data": {}
}
```

Error

```json
{
    "success": false,
    "message": "Product not found.",
    "data": null
}
```

---

# 6. Status Codes

200 OK

201 Created

204 No Content

400 Bad Request

401 Unauthorized

403 Forbidden

404 Not Found

409 Conflict

422 Validation Error

500 Internal Server Error

Use the correct HTTP status code.

---

# 7. Authentication

Protected endpoints require JWT.

Authorization

Bearer <token>

Never place tokens inside query parameters.

---

# 8. Error Handling

Backend should return meaningful messages.

Frontend should display friendly messages.

Never expose

- Stack traces
- SQL errors
- Internal exceptions

---

# 9. Pagination

Large collections SHOULD support pagination.

Example

GET /api/products?page=1&size=20

Return

- items
- page
- size
- totalItems
- totalPages

---

# 10. Filtering

Use query parameters.

Examples

/api/products?category=Flower

/api/products?search=Rose

/api/products?sort=name

Combine filters when appropriate.

---

# 11. Date & Time

Use ISO 8601.

Example

2026-06-29T08:30:00Z

Store timestamps in UTC.

---

# 12. File Upload

Files are uploaded through Spring Boot.

Flutter never uploads directly to Supabase Storage.

Store only file URLs in the database.

---

# 13. Security

Never expose

- Passwords
- JWT secrets
- Internal IDs
- Database credentials

Always validate user permissions.

---

# 14. Versioning

Future APIs should use versioning.

Example

/api/v1/products

---

# 15. Source of Truth

If this document conflicts with implementation, update the implementation to match these rules.