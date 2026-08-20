---
name: code-quality-principles
description: "SOLID/DRY/YAGNI/KISS design checks and DDD-style layering pitfalls beyond the P1/P2 review gate"
---

# Code Quality Principles

## Rules

1. Single Responsibility: a class/function should have exactly one reason to change. If describing its job needs "and," split it.
2. Don't Repeat Yourself: duplicated validation, error handling, or business logic should be extracted once it appears a second time with the same intent — not left copy-pasted "for now."
3. YAGNI: don't build an abstraction, config flag, or extension point for a requirement that hasn't actually been asked for yet.
4. KISS: prefer the straightforward solution over a cleverer one unless the simple version demonstrably can't meet the requirement.
5. Dependency Inversion: depend on an interface/abstraction, not a concrete implementation, wherever the concrete type could plausibly vary (a datastore, an external client, a strategy).
6. If using DDD-style entities: business rules that determine what an entity **can** do live as entity methods; input/format checks that determine whether a request **should** proceed live in a separate validator — don't blend the two into one giant validation pass.
7. Never call a repository/persistence method directly from a controller — go through the service layer, even for a "trivial" read.
8. Watch for N+1 queries wherever a collection is iterated and each item triggers its own lazy-loaded fetch — batch or eagerly fetch instead.
9. Stream large file/data operations — don't load an entire large payload into memory when it can be processed incrementally.

## Anti-patterns

- A method over ~30 lines doing several distinct things (validate, then persist, then format a response) — split by responsibility.
- Hardcoded magic numbers/constants with no name explaining what they mean or why that value.
- An abstraction added "because we might need it later" with exactly one implementation and no second caller in sight.
- A loop over a JPA collection where each iteration triggers a separate lazy-load query — check the generated SQL, not just the Java code, to catch this.
- Comments explaining what already-obvious code does, instead of explaining a genuinely non-obvious business rule.
- A controller calling `repository.save()` directly, bypassing service-layer validation that every other write path goes through.

## Examples

**N+1 — do this:**
```java
List<Order> orders = orderRepository.findAllWithItemsById(ids); // one query, fetch-joined
```

**Not this:**
```java
List<Order> orders = orderRepository.findAllById(ids);
orders.forEach(o -> o.getItems().size()); // triggers one lazy-load query per order
```

**Review output shape, when reporting quality findings separately from the P1/P2 gate:**
```markdown
## Code Quality Notes (non-blocking)
- [OrderService.java:42] SRP: this method validates, persists, and formats the response — split into three.
- [InventoryRepo.java:18] N+1: findAllById + per-item lazy load — use a fetch join.
```
