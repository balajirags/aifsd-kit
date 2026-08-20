---
name: backend-spring-boot
description: "Spring Boot conventions: constructor injection, DTOs over entities, service-layer boundaries, type-safe config"
---

# Backend (Spring Boot)

> Adapted from `.agents/skills/java-springboot/SKILL.md`. Build tool, package structure conventions, and coverage thresholds belong in `docs/project-context.md`, not here.

## Rules

1. Use constructor injection for every required dependency; declare the fields `private final`. Never use field injection (`@Autowired` on a field).
2. Never expose a JPA entity directly from a controller — return a DTO. Accept DTOs on write endpoints, not entities.
3. Validate every request DTO with Bean Validation (`@Valid` + `@NotNull`/`@Size`/etc.) — never hand-roll null checks for what an annotation already covers.
4. Encapsulate business logic in `@Service` classes only; services are stateless — never store per-request state in a service field.
5. Apply `@Transactional` at the most granular method that needs it, not broadly at the class level or on read-only query methods that don't need a transaction.
6. Use Spring Data JPA repositories for standard CRUD; drop to `@Query`/Criteria API only for genuinely complex queries — don't hand-write SQL for what a derived query method already expresses.
7. Use DTO projections when a query only needs a subset of columns — never fetch a full entity graph to read two fields.
8. Externalize all configuration via `application.yml` + `@ConfigurationProperties` (type-safe binding) — never read config with ad-hoc `@Value` scattered across classes for structured config.
9. Never hardcode a secret, connection string, or credential in `application.yml` — inject via environment variable or a secrets manager.
10. Use SLF4J with parameterized messages (`log.info("Processing user {}", userId)`) — never string-concatenate log messages.

## Anti-patterns

- `@Autowired private SomeService service;` — field injection hides required dependencies and breaks constructing the class in a test without Spring.
- A `@RestController` method returning a JPA `@Entity` directly — leaks persistence structure (and lazy-loading proxies) into the API contract.
- `@Transactional` on an entire `@Service` class when only one write method needs it — widens lock/transaction scope unnecessarily.
- Business logic living in the controller ("just this one calculation, it's simple") instead of the service layer.
- `@Value("${some.nested.prop}")` repeated across five classes instead of one `@ConfigurationProperties` class.

## Examples

**Constructor injection — do this:**
```java
@Service
public class OrderService {
    private final OrderRepository orderRepository;
    private final InventoryClient inventoryClient;

    public OrderService(OrderRepository orderRepository, InventoryClient inventoryClient) {
        this.orderRepository = orderRepository;
        this.inventoryClient = inventoryClient;
    }
}
```

**Type-safe config — do this:**
```java
@ConfigurationProperties(prefix = "orders")
public record OrdersProperties(int maxItemsPerOrder, Duration reservationTtl) {}
```
Not five separate `@Value("${orders.max-items-per-order}")` fields spread across unrelated classes.
