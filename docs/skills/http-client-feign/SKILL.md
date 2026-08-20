---
name: http-client-feign
description: "Outbound Feign HTTP client conventions: timeouts, centralized retries, typed error decoding, idempotent retries"
---

# HTTP Client (Feign)



## Rules

1. Always set explicit connect and read timeouts, and a max connection pool size — never rely on client defaults, which are often "wait indefinitely."
2. Disable Feign's own retries (`Retryer.NEVER_RETRY`); centralize retry + backoff + circuit-breaking in Resilience4j (or equivalent) around the client call — never stack two independent, uncoordinated retry mechanisms.
3. Implement a reusable `ErrorDecoder` that maps HTTP status codes to typed domain exceptions — never let a raw `FeignException` propagate past the client boundary.
4. Model request/response as immutable DTOs (records or `@Builder`), never JPA entities — and mark response DTOs `@JsonIgnoreProperties(ignoreUnknown = true)` so an upstream adding a field doesn't break deserialization.
5. Only retry a call automatically when it's safe to: GET and other idempotent operations, or a POST that carries an `Idempotency-Key` the server dedupes on. Never blindly retry a non-idempotent write whose outcome is unknown (e.g. a timeout) without a way to detect duplication.
6. Prefix the client's base path with a version (`/v1`); when a breaking change is needed, add a new client interface (`CatalogClientV2`) rather than mutating the existing contract.
7. Add a `RequestInterceptor` to propagate auth and correlation/trace headers on every outbound call — don't leave trace context to stop at the service boundary.
8. Set client logging to a minimal level (e.g. `BASIC`) in any deployed environment; `FULL` request/response logging is a debug-only setting, since it can capture secrets or PII.
9. Never log a client's auth header or any PII field it carries — mask sensitive headers before logging.

## Anti-patterns

- Default Feign retry settings left enabled alongside an app-level retry wrapper — a transient failure now gets retried by both layers, multiplying load during an incident.
- No timeout configured — a slow upstream exhausts the calling service's thread pool.
- Blindly retrying a POST that creates a resource, with no idempotency key — a timeout-then-retry can create the resource twice.
- Returning `ResponseEntity<byte[]>` for a large payload instead of streaming it.
- Mixing entity types into the client's request/response DTOs — leaks this service's persistence model into the wire contract with another service.
- `Logger.Level.FULL` left on in a deployed environment — logs may capture tokens or PII from headers/bodies.

## Examples

**Client contract documentation (keep one per client):**
```java
/**
 * Client: Catalog API
 * Base URL: ${catalog.base-url}
 * Timeouts: connect=2s, read=3s, call=5s
 * Retries: none in Feign (Resilience4j: maxAttempts=3, backoff=200ms)
 * CircuitBreaker: failureRateThreshold=50%, window=50
 * Auth: OAuth2 client-credentials
 * Error model: 4xx/5xx mapped via DomainErrorDecoder
 */
```

**Immutable response DTO tolerant of upstream additions:**
```java
@JsonIgnoreProperties(ignoreUnknown = true)
public record CatalogItemResponse(String sku, String name, BigDecimal price) {}
```
