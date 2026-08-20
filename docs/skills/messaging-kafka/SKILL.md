---
name: messaging-kafka
description: "Kafka topic naming, producer/consumer reliability, schema compatibility, and DLQ handling conventions"
---

# Messaging (Kafka)


## Rules

1. Name topics `domain.context.eventName.v1` — no environment name embedded in the topic name (environments are separate clusters/namespaces, not name suffixes).
2. Key every record that has an ordering requirement (e.g. by `orderId`) — never publish an unkeyed record when downstream order matters.
3. Producers: enable idempotence (`enable.idempotence=true`), `acks=all`, and bound `max.in.flight.requests.per.connection` to ≤5 — never leave producer retries unbounded with idempotence off.
4. Consumers: use manual offset commits (`enable-auto-commit: false`) — never auto-commit before processing completes, and never auto-commit under heavy/slow processing.
5. Every consumer needs a retry + DLQ (dead-letter topic) path. A poison-pill message (one that will never succeed) must be routed to the DLQ and acknowledged, not retried forever.
6. Keep consumer processing idempotent — if a message handler writes to a DB, use a unique constraint or idempotency key so redelivery (at-least-once) doesn't double-apply the effect.
7. Use Schema Registry (Avro/Protobuf) with `BACKWARD` or `BACKWARD_TRANSITIVE` compatibility. Evolve schemas by adding optional fields with defaults — never remove or rename a field in place; version the topic instead (`v2`).
8. Propagate a correlation ID (and trace ID, if tracing is set up) as a message header on every publish, and bind it back into the log context (e.g. MDC) on every consume.
9. Keep listener processing time bounded under `max.poll.interval.ms`, or switch to a batch listener — never do long blocking I/O per record in a listener that can trigger a rebalance.
10. Never log a full message payload if it may contain PII or secrets — log identifying fields (topic, partition, offset, key, correlation id) instead.

## Anti-patterns

- Auto-commit enabled with slow/heavy per-record processing — offsets advance before work is confirmed done, silently dropping messages on a crash.
- Publishing without a key when consumers rely on per-entity ordering — messages for the same entity can land on different partitions and process out of order.
- Unbounded producer retries with idempotence disabled — can duplicate or reorder records under retry storms.
- Breaking schema compatibility (removing/renaming a field) without bumping the topic version — old consumers start failing to deserialize.
- Treating every processing exception as retryable — a poison-pill message retried forever blocks the partition instead of going to the DLQ.

## Examples

**Producer — keyed, callback-based, never blocking on `.get()`:**
```java
public void publishReservationCreated(ReservationCreated event) {
  var rec = new ProducerRecord<>(Topics.RESERVATION_CREATED_V1, event.getOrderId(), event);
  rec.headers().add("x-correlation-id", corrId().getBytes(UTF_8));
  kafkaTemplate.send(rec).whenComplete((res, ex) -> {
    if (ex != null) log.error("kafka.publish.failed topic={} key={}", Topics.RESERVATION_CREATED_V1, event.getOrderId(), ex);
  });
}
```

**Consumer — manual ack, DLQ on poison pill:**
```java
@KafkaListener(topics = Topics.RESERVATION_CREATED_V1)
public void onMessage(ConsumerRecord<String, ReservationCreated> rec, Acknowledgment ack) {
  try {
    service.handle(rec.key(), rec.value(), rec.headers());
    ack.acknowledge();
  } catch (PoisonPillException e) {
    sendToDlt(rec, e);
    ack.acknowledge(); // skip the bad message, don't retry it forever
  }
  // other exceptions propagate to the container's retry/backoff error handler
}
```
