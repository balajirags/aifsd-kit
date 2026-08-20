---
name: logging-observability
description: "Structured JSON logging, correlation IDs, log levels, and never logging secrets or PII"
---

# Logging & Observability

## Rules

1. Every log line is structured JSON to stdout, not free text to a file — 12-factor treats logs as an event stream, and structured output is what makes them queryable.
2. Every log line includes at minimum: `timestamp`, `level`, `service`, `env`, `message`. Include `trace_id`/`span_id`/`correlation_id` whenever they're available in context.
3. Use parameterized logging (`log.info("Stock movement recorded", kv("item_id", itemId))`) — never string-concatenate a variable into the message.
4. Log an exception once, at the point it's handled, at `ERROR` with the full stack trace — never re-log the same exception at every layer it passes through, and never swallow it by logging only `e.getMessage()`.
5. Pick the level deliberately: `DEBUG` only for local dev (never in a deployed environment), `INFO` for a business event that succeeded, `WARN` for degraded-but-functional (retry, cache miss spike, slow query), `ERROR` for a failed operation that needs attention.
6. Never log a password, token, API key, card number, national ID, or other PII/secret at any level, in any environment.
7. Never log a full request/response body in a deployed environment — it may contain any of the above without the log statement's author realizing it.
8. Propagate the correlation ID across process boundaries: bind it into the log context (e.g. MDC) from an inbound request header, and forward it as a header/message-header on every outbound HTTP call or published event.
9. In a loop, log entry and exit (with a count), not every iteration — a tight loop logging per-item drowns the log stream and the individual signal.

## Anti-patterns

- `log.info("Stock movement recorded for item " + itemId);` — string concatenation instead of parameterized args.
- `log.error(e.getMessage());` — swallows the stack trace, making the error unactionable.
- Logging the same caught exception at the repository, service, and controller layer — three log lines for one failure, none of which add new information.
- A `DEBUG` log line left enabled by default in a shipped config, dumping intermediate values in production.
- Logging an entire incoming request body "for debugging" on an endpoint that accepts a password or payment field.

## Examples

**Java / Spring Boot — parameterized, structured (Logback + logstash-logback-encoder):**
```java
private static final Logger log = LoggerFactory.getLogger(InventoryService.class);

log.info("Stock movement recorded", kv("item_id", itemId), kv("delta", delta));
log.warn("Cache miss — falling back to DB", kv("key", cacheKey));
log.error("Failed to publish Kafka event", kv("topic", topic), kv("item_id", itemId), e);
```

**Correlation ID via a servlet filter, bound to MDC:**
```java
@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class CorrelationIdFilter extends OncePerRequestFilter {
    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
            throws IOException, ServletException {
        String id = Optional.ofNullable(req.getHeader("X-Correlation-ID")).orElse(UUID.randomUUID().toString());
        MDC.put("correlation_id", id);
        res.setHeader("X-Correlation-ID", id);
        try { chain.doFilter(req, res); } finally { MDC.clear(); }
    }
}
```

**Propagating correlation ID onto a Kafka message:**
```java
record.headers().add("correlation_id", MDC.get("correlation_id").getBytes());
```
