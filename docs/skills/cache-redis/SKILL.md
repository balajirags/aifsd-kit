---
name: cache-redis
description: "Redis key naming, TTL, cache-aside, distributed locking, and rate-limiting rules"
---

# Cache (Redis)

## Rules

1. Key format is `<app>:<env>:<entity>:<id>` — always include the app name (avoids collisions between services sharing a Redis instance) and use `:` as the separator, never `/` or `.`.
2. Every cache key must have a TTL. Never write a cache-purpose key without an expiry — an un-expiring "cache" is a memory leak and a stale-data bug waiting to happen.
3. Use cache-aside (read cache → miss → read DB → write cache with TTL) for read-through caching — don't hand-roll a different invalidation strategy without a reason.
4. Stateless app servers keep session state in Redis, not in-process memory (12-factor: processes are disposable) — never rely on sticky sessions plus in-memory session storage.
5. A distributed lock must always carry a TTL (guards against a crashed holder never releasing it) and a unique lock ID (guards against releasing a lock you don't own) — release via an atomic check-and-delete (Lua script), never a plain `DEL`.
6. Rate limiting must be atomic (a Lua script or a pipelined transaction) — never read-then-write the counter as two separate round trips, which races under concurrent requests.
7. Redis Pub/Sub is not durable — a subscriber that's briefly disconnected loses those messages. Use it only for best-effort signals (cache invalidation broadcast, live notifications); use Kafka (or Streams, if durability with less infrastructure is acceptable) when delivery must be guaranteed.
8. Set `maxmemory-policy` deliberately per use: `allkeys-lru`/`allkeys-lfu` for pure cache, `volatile-lru` when only some keys carry a TTL, `noeviction` for session/lock data where losing a key silently would be a correctness bug, not a cache miss.

## Anti-patterns

- A key written with `SET key value` and no `EX`/`PX` — it lives forever, silently grows memory usage, and can serve arbitrarily stale data.
- Storing session data in-process ("it's fine, sticky sessions handle it") — breaks the moment you scale horizontally or a pod restarts.
- `GET` then `SET` for a counter/lock across two calls — another request can interleave between them; use `INCR`, `SET ... NX`, or a Lua script instead.
- Releasing a lock with a plain `DEL key` — if the lock expired and someone else acquired it, you just deleted their lock.
- Using Pub/Sub for anything that must not be lost (e.g. an order-placed event) — there is no redelivery if the subscriber was offline.

## Examples

**Cache-aside (Spring):**
```java
@Cacheable(value = "inventory-items", key = "#id", unless = "#result == null")
public InventoryItem findById(UUID id) {
    return inventoryRepository.findById(id).orElseThrow();
}

@CacheEvict(value = "inventory-items", key = "#item.id")
public InventoryItem update(InventoryItem item) {
    return inventoryRepository.save(item);
}
```

**Distributed lock — TTL + unique owner + atomic release:**
```java
RLock lock = redisson.getLock("lock:reservation:" + id);
if (!lock.tryLock(3, 30, TimeUnit.SECONDS)) {
    throw new ConflictException("Another operation is in progress");
}
try {
    doProcess(id);
} finally {
    if (lock.isHeldByCurrentThread()) lock.unlock();
}
```
