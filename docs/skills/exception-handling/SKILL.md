---
name: exception-handling
description: "Layered exception handling with a domain exception hierarchy and RFC 7807 ProblemDetail error responses"
---

# Exception Handling

## Rules

1. Use one layered strategy: controllers never catch business exceptions themselves — a `@ControllerAdvice` global handler maps domain exceptions to HTTP responses.
2. Define domain exceptions as a small hierarchy under one base (e.g. `DomainException`) carrying a stable, machine-readable `errorCode` — never throw a bare `RuntimeException`/`Exception` from service/domain code.
3. Every error response uses RFC 7807 `ProblemDetail` (or an equivalent consistent error envelope) — never a bespoke error shape per endpoint.
4. Never expose a stack trace in an API response. Log it server-side (at `ERROR` for unexpected failures) and return only the safe `ProblemDetail` fields to the client.
5. Log expected domain errors (404, 409, 422) at `WARN`; log genuinely unexpected exceptions at `ERROR` with the full exception object, not just its message.
6. Never catch an exception and silently discard it — either handle it meaningfully, log and rethrow, or let it propagate to the global handler.
7. Map exceptions from integration boundaries (Feign/HTTP client, JPA, Kafka) into domain exceptions at the boundary — never let a raw `FeignException` or `DataAccessException` leak up to the controller layer.
8. Don't use exceptions for expected control flow (e.g. "not found" as part of a normal lookup-or-create path where absence is routine) — reserve them for genuinely exceptional conditions.

## Anti-patterns

- `catch (Exception e) { }` — swallows the failure with no log, no rethrow; the caller has no idea anything went wrong.
- A controller method with its own `try/catch` mapping to a one-off JSON error shape instead of letting the global `@ControllerAdvice` handle it — every endpoint ends up with a slightly different error format.
- Returning the raw exception message (which may contain internal class names, SQL fragments, or file paths) directly in the API response body.
- A generic `catch (Exception e) { throw new RuntimeException(e); }` re-wrap that loses the original exception's identity for the global handler to map correctly.
- Using `Optional.orElseThrow(RuntimeException::new)` instead of a specific domain exception with a real error code and message.

## Examples

**Domain exception hierarchy:**
```java
public abstract class DomainException extends RuntimeException {
    private final String errorCode;
    protected DomainException(String errorCode, String message) { super(message); this.errorCode = errorCode; }
    public String getErrorCode() { return errorCode; }
}

public class ResourceNotFoundException extends DomainException {
    public ResourceNotFoundException(String resourceType, Object id) {
        super("RESOURCE_NOT_FOUND", "%s not found with identifier: %s".formatted(resourceType, id));
    }
}
```

**Global handler mapping to `ProblemDetail`:**
```java
@ControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(ResourceNotFoundException.class)
    public ProblemDetail handleNotFound(ResourceNotFoundException ex) {
        log.warn("Resource not found: {}", ex.getMessage());
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, ex.getMessage());
        problem.setProperty("errorCode", ex.getErrorCode());
        return problem;
    }

    @ExceptionHandler(Exception.class)
    public ProblemDetail handleUnexpected(Exception ex) {
        log.error("Unexpected error", ex);
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(HttpStatus.INTERNAL_SERVER_ERROR, "An unexpected error occurred");
        problem.setProperty("errorCode", "INTERNAL_ERROR");
        return problem;
    }
}
```
