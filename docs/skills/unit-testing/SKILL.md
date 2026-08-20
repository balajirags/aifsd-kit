---
name: unit-testing
description: "JUnit 5 + Mockito + AssertJ unit-test conventions: one behavior per test, mock only externals, meaningful coverage"
---

# Unit Testing


## Rules

1. One behavior per test method. Name it `should<Behavior>_when<Condition>()`, and structure the body as Given/When/Then (or Arrange/Act/Assert) — never a test that asserts three unrelated behaviors.
2. Mock external dependencies only (`@Mock` + `@InjectMocks` via `@ExtendWith(MockitoExtension.class)`) — never mock the class under test itself.
3. Read and understand the whole class before writing tests for it: enumerate its public methods, every conditional branch, every dependency interaction, and every validation/error path — write tests to cover what you actually found, not just the happy path you assumed.
4. Group tests into `@Nested` classes by category (e.g. `SuccessCases`, `FailureCases`, `EdgeCases`, `Validation`) so a failing suite immediately signals what kind of behavior broke.
5. Use `assertThat(...)` (AssertJ) for assertions, and `verify(mock).method(...)` to confirm required interactions — a test that only checks a return value but never verifies a required side-effect call is incomplete.
6. Test edge cases explicitly: null/empty collections, boundary values, and every custom validation annotation individually — not just one combined "valid input" case.
7. Don't write a unit test for a class with zero conditionals/branches/custom logic — a plain DTO record, a JPA entity with only getters/setters, a trivial enum, or a `@Configuration` class with only `@Bean` declarations. If it later gains validation or behavior, it earns a test then.
8. Exclude the classes covered by Rule 7 from coverage tooling (e.g. JaCoCo) at the package level so they don't distort the project's real coverage number — never exclude a class that has actual business logic just to hit a target.
9. Keep the suite fast — no real database/network calls in a unit test; that's what integration tests (Testcontainers, `@SpringBootTest`) are for.

## Anti-patterns

- Mocking the class under test (e.g. spying on the very service being tested) instead of only its dependencies.
- One test method asserting the happy path, an error path, and a validation rule all in a single body — a failure tells you nothing about which behavior broke.
- Writing a unit test for a Java record DTO with no custom logic — pure noise, no signal.
- Excluding `OrderService` from coverage "to hit the number" because a few branches are hard to test — that's exactly the class that needs the coverage.
- A test suite that hits a real database or makes a real network call "just this once" — flaky and slow, and it stops being a unit test.

## Examples

**Structure:**
```java
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {
    @Mock InventoryClient inventoryClient;
    @Mock OrderRepository orderRepository;
    @InjectMocks OrderService orderService;

    @Nested class SuccessCases {
        @Test
        void shouldCalculateTotal_whenValidOrder() {
            // given
            when(inventoryClient.isAvailable(anyString())).thenReturn(true);
            // when
            var result = orderService.placeOrder("sku-123", 2);
            // then
            assertThat(result.total()).isEqualTo(200);
            verify(orderRepository).save(any());
        }
    }
}
```

**Coverage-exclusion config for genuinely behavior-free classes only (Gradle/JaCoCo):**
```groovy
def coverageExclusions = ['**/dto/**', '**/response/**', '**/config/**']
jacocoTestReport { afterEvaluate { classDirectories.setFrom(files(classDirectories.files.collect {
    fileTree(dir: it, exclude: coverageExclusions) })) } }
```
Never add a package with real logic (services, controllers, repositories) to this list.
