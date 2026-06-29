---
trigger: model_decision
description: Use this rule when handling exceptions, API failures, validation errors, loading states, retries, logging, user-facing error messages, or implementing global error handling in Flutter or Spring Boot.
---

# AgentHub Error Handling Rules

These rules define the required error contract across Supabase, Electron main/preload, renderer services, React screens, background jobs, and vendor integrations. Apply them to every new module and every substantially changed error path. Existing violations are migration debt; do not introduce new ones.

## Contents

1. Principles
2. Error contract
3. Ownership by layer
4. UI presentation
5. Logging and privacy
6. Async, retry, and transactions
7. Required and forbidden patterns
8. Test contract

## 1. Principles

- Errors MUST be normalized once near their source and preserve the original cause internally.
- UI MUST receive a safe application error, never a raw Supabase, Postgres, vendor, fetch, or Electron error.
- Expected failures MUST be modeled explicitly; unexpected failures MUST remain observable and reach a controlled fallback.
- Empty data, permission denial, cancellation, and operation failure MUST remain distinguishable states.
- Error handling MUST preserve user input and recoverable workflow state.
- Security and privacy MUST take precedence over diagnostic convenience.

## 2. Error Contract

Use one shared `AppError` contract under `src/shared/errors/`:

```ts
type ErrorCode =
  | 'VALIDATION'
  | 'AUTHENTICATION_REQUIRED'
  | 'PERMISSION_DENIED'
  | 'NOT_FOUND'
  | 'CONFLICT'
  | 'RATE_LIMITED'
  | 'NETWORK'
  | 'TIMEOUT'
  | 'SERVICE_UNAVAILABLE'
  | 'DATA_INTEGRITY'
  | 'CANCELLED'
  | 'INTERNAL';

interface AppError {
  code: ErrorCode;
  userMessage: string;
  retryable: boolean;
  correlationId: string;
  fieldErrors?: Record<string, string>;
}

type Result<T> =
  | { ok: true; data: T }
  | { ok: false; error: AppError };
```

- Shared/public `AppError` MUST contain only serializable, user-safe fields.
- Internal errors MAY additionally hold `cause`, stack, provider code, operation, actor, workspace, and structured diagnostic context.
- `userMessage` MUST be stable, actionable, and localized at the presentation boundary when localization exists.
- `correlationId` MUST allow support and logs to locate the same failure without exposing internals.
- Validation, conflict, not-found, and permission outcomes SHOULD return `Result<T>` from application services.
- Programmer errors and violated internal invariants SHOULD throw an internal `AppError` and be caught by the nearest application boundary.
- Do not combine nullable data and error into ambiguous return values.

## 3. Ownership By Layer

### Supabase And Vendor Adapters

- Check every returned `{ error }`; ignored errors are forbidden.
- Map provider-specific codes to `ErrorCode` in one adapter, not inside components.
- Preserve Postgres/Supabase codes internally for diagnostics, but do not render their messages directly.
- Treat zero rows as empty or not-found according to the query contract, never as a generic failure.
- Request explicit columns and attach operation and workspace context to internal logs.

### Application Services

- Renderer components MUST call typed service functions rather than repeat Supabase error mapping.
- Services MUST own normalization, timeout, cancellation, retry policy, and `Result<T>` construction.
- Services MUST avoid showing UI, calling toast, or mutating React state.

### Electron IPC

- IPC MUST return a discriminated serializable envelope: `{ ok: true, data }` or `{ ok: false, error: AppError }`.
- Main-process handlers MUST validate input, authorize the operation, normalize errors, and log once.
- Raw `Error` objects, stacks, credentials, provider payloads, and database messages MUST NOT cross preload.
- Preload APIs MUST expose typed operation-specific methods, not raw IPC primitives.

### React Renderer

- Event handlers MUST handle `Result<T>` and choose the presentation defined below.
- React components MUST NOT map raw infrastructure errors.
- Render failures MUST be caught by an application-level Error Boundary with a recovery action and correlation ID.
- Global `error` and `unhandledrejection` handlers MAY report unexpected failures, but MUST NOT replace local handling for expected operations.

## 4. UI Presentation

Use common components from `src/renderer/components/ui/`:

| Failure | Required presentation |
| --- | --- |
| Field validation | `FormField` inline error; focus first invalid field |
| Authentication | Auth-level `InlineAlert`; preserve non-secret form input |
| Permission denied | Page/section permission state; do not present as empty data |
| Initial page query | `ErrorState` with retry when retryable |
| Mutation failure | Keep form/dialog open and show `InlineAlert` or error toast |
| Mutation success | Close only after success; show success toast when useful |
| Destructive action | `ConfirmDialog`; failure remains visible without losing context |
| Background operation | Non-blocking toast/status plus durable task state |
| Unexpected render error | Error Boundary fallback with reload/retry and correlation ID |

- Native `alert()` and `confirm()` MUST NOT be used.
- Raw `error.message` MUST NOT be rendered.
- Retry controls MUST appear only when `retryable` is true.
- Toast MUST NOT be the only location for field errors or errors requiring a user decision.
- A failed fetch MUST NOT silently render the empty state.
- Pending UI MUST prevent duplicate submission and remain pending until the operation settles.

## 5. Logging And Privacy

- Use a centralized structured logger; production code MUST NOT call `console.error` directly outside the logger implementation.
- Log each failure once at the layer that has enough context to act on it.
- Include: timestamp, level, correlation ID, operation, error code, workspace ID when safe, actor ID when safe, retry count, duration, and outcome.
- Redact API keys, tokens, authorization headers, cookies, credentials, passwords, personal data, prompts, model output, and raw vendor payloads.
- User-facing messages MUST NOT contain stack traces, SQL, table names, RLS details, internal URLs, or provider secrets.
- Cancellation and expected validation failures SHOULD NOT be logged as server errors.
- Security-sensitive failures SHOULD produce an audit event without secret values.

## 6. Async, Retry, And Transactions

- External calls MUST support a timeout and `AbortSignal` where available.
- Retry only transient `NETWORK`, `TIMEOUT`, `RATE_LIMITED`, or `SERVICE_UNAVAILABLE` failures.
- Use bounded exponential backoff with jitter, maximum three attempts unless a provider contract requires less.
- Respect `Retry-After` and provider rate-limit metadata.
- Never retry validation, authentication, permission, conflict, or deterministic business-rule failures.
- Never retry a mutation unless it is idempotent or protected by an idempotency key/constraint.
- Workspace-dependent reads MUST ignore or cancel stale results after workspace changes.
- Multi-table operations that must succeed together MUST use a Supabase/Postgres RPC transaction.
- If atomicity is impossible, define and test explicit compensation and recovery behavior.
- Background agent tasks MUST persist recoverable state before external execution and represent terminal failure explicitly.

## 7. Required And Forbidden Patterns

Required:

- Exhaustive `switch` or mapping for every `ErrorCode` at presentation boundaries.
- `unknown` in catch clauses followed by centralized normalization.
- `finally` or equivalent cleanup for pending state.
- Stable error codes in tests; do not assert fragile provider message text.
- Error Boundary around the authenticated application and major plugin/extension surfaces.

Forbidden:

- `catch (error: any)`.
- Empty catch blocks or promise chains without rejection handling.
- `console.error` scattered through components and services.
- Returning `[]`, `null`, or success after an infrastructure failure.
- Showing raw `error.message` to users.
- Calling `alert()` or `confirm()`.
- Ignoring Supabase `{ error }` results.
- Retrying all errors indiscriminately.
- Closing a form before its mutation succeeds.
- Logging secrets or full external payloads.
- Duplicating provider-error mapping in multiple screens.

## 8. Test Contract

Every changed operation MUST test the relevant cases:

1. Success and correct pending-state cleanup.
2. Validation or deterministic business failure.
3. Permission/authentication denial.
4. Network/timeout failure and retry limit when retryable.
5. Non-retryable failure is attempted once.
6. Duplicate activation does not duplicate mutation.
7. Cancellation or stale result does not overwrite current state.
8. User message is safe and correlation ID is present.
9. Logs contain structured context and redact secrets.
10. Empty state remains distinct from error state.
11. Multi-step writes roll back or execute documented compensation.
12. IPC serializes only the public `AppError` envelope.

Reviewers MUST block new code that violates a MUST rule. Until legacy migration is complete, static enforcement SHOULD target new and substantially changed files, while tests SHOULD cover every newly touched error path.
