---
trigger: always_on
---

# System Architecture

This document defines the architecture of the Supermarket Management System.

All developers and AI assistants MUST follow this architecture when implementing new features.

---

# 1. Technology Stack

## Frontend

- Flutter
- Material Design 3
- Riverpod
- GoRouter
- Dio

---

## Backend

- Spring Boot
- Spring Web
- Spring Data JPA
- Spring Security
- JWT Authentication

---

## Database

- PostgreSQL (Supabase)

---

## Storage

- Supabase Storage

---

# 2. High-Level Architecture

The system follows a three-tier architecture.

```
Flutter Application
        │
        │ REST API
        ▼
Spring Boot Backend
        │
        │ JPA
        ▼
Supabase PostgreSQL
```

Rules

- Flutter MUST communicate only with Spring Boot.
- Spring Boot is the single source of truth.
- Flutter MUST NEVER access PostgreSQL directly.
- Business logic MUST remain in Spring Boot.

---

# 3. Frontend Architecture

Flutter is responsible for:

- User Interface
- State Management
- Navigation
- API Communication
- Input Validation
- User Experience

Flutter MUST NOT contain business rules that belong to the backend.

---

# 4. Backend Architecture

Spring Boot is responsible for:

- Authentication
- Authorization
- Business Logic
- Database Operations
- Validation
- File Management
- API Responses

---

# 5. Backend Layers

Every feature MUST follow this flow.

```
Controller
      │
      ▼
Service
      │
      ▼
Repository
      │
      ▼
Database
```

Responsibilities

### Controller

- Receive HTTP requests
- Validate request format
- Return HTTP responses
- Never contain business logic

---

### Service

- Business rules
- Validation
- Transactions
- Call repositories
- Coordinate multiple services

---

### Repository

- Database access only
- No business logic

---

### Entity

- Represents database tables

---

### DTO

- Represents API request/response objects
- Never expose Entity directly to clients

---

# 6. Frontend Data Flow

Every feature SHOULD follow this flow.

```
Screen

↓

Provider

↓

Service

↓

REST API

↓

Spring Boot
```

Widgets should never communicate with APIs directly.

---

# 7. API Communication

Communication uses REST APIs over HTTPS.

Example

```
GET    /api/products

GET    /api/products/{id}

POST   /api/products

PUT    /api/products/{id}

DELETE /api/products/{id}
```

All requests should return a consistent response structure.

Example

```json
{
    "success": true,
    "message": "Product created successfully.",
    "data": { }
}
```

---

# 8. Authentication

Authentication uses JWT.

Flow

```
Login

↓

Spring Boot

↓

JWT

↓

Flutter Secure Storage

↓

Authorization Header

↓

Protected APIs
```

Unauthorized users MUST be redirected to Login.

---

# 9. Authorization

Authorization is role-based.

Supported roles

- Admin
- Manager
- Cashier
- Inventory Staff
- Sales Associate

Permissions MUST always be verified on the backend.

Frontend role checks are only for UI presentation.

---

# 10. Database

Supabase PostgreSQL is the primary database.

Rules

- Never modify the database directly from Flutter.
- All database access goes through Spring Boot.
- Repository classes are the only layer allowed to access the database.

---

# 11. File Storage

Product images and other uploaded files are stored in Supabase Storage.

Rules

- Uploads are handled by Spring Boot.
- Flutter uploads files through backend APIs.
- Store only file URLs in the database.

---

# 12. Error Handling

Backend

- Return meaningful HTTP status codes.
- Return consistent error responses.

Frontend

- Display user-friendly messages.
- Never expose stack traces.
- Handle Loading, Empty, Error, and Success states.

---

# 13. Logging

Backend

- Log warnings and errors.
- Never log passwords or JWT tokens.

Frontend

- Remove debug logs before release.
- Avoid logging sensitive information.

---

# 14. Security

Passwords MUST be hashed.

JWT secrets MUST be stored in environment variables.

Never commit:

- .env
- API Keys
- Database credentials
- JWT secrets

Use HTTPS in production.

---

# 15. Scalability

Features should be independent.

Adding a new feature SHOULD require only:

- New Controller
- New Service
- New Repository
- New Entity
- New DTO
- New Flutter Screen
- New Provider
- New Service

Existing features should require minimal modification.

---

# 16. Source of Truth

System architecture defined in this document takes precedence over implementation details.

When architecture conflicts with generated code, this document MUST be followed.