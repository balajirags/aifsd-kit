---
name: clean-code
description: "Naming, function size, null-handling, and comment discipline for readable, intention-revealing code"
---

# Clean Code

> Adapted from `.agents/skills/clean-code/SKILL.md` (Robert C. Martin's *Clean Code*). Style/readability guidance for whoever is writing code — out of scope for `docs/team/reviewer.agent.md`, which reports only P1/P2 (security/critical, architecture/Spec drift), never style or naming.

## Rules

1. Names must reveal intent — `elapsedTimeInDays`, not `d`. A class name is a noun (`Customer`), a method name is a verb (`postPayment`) — never the reverse.
2. A function should do one thing, at one level of abstraction — don't mix high-level orchestration with low-level detail (e.g. a regex or a raw SQL fragment) in the same function as business logic.
3. Prefer zero function arguments, tolerate one or two, treat three or more as a smell needing a real justification (or a parameter object).
4. Don't comment bad code — rewrite it so the code states its own intent. A comment is for something the code genuinely can't express (a legal note, a non-obvious external-library quirk, intentional context that would otherwise be lost).
5. Never return `null` from a method whose caller has to guess whether to check for it — return `Optional`, an empty collection, or a documented sentinel instead. Never pass `null` as an argument either.
6. Keep classes small and single-responsibility — if you can't describe a class's job in one sentence without "and," split it.
7. Hide implementation behind interfaces (data abstraction); respect the Law of Demeter — avoid reaching through `a.getB().getC().doSomething()` chains.
8. Use exceptions for error handling, not return codes — and write the surrounding try/catch/finally structure before filling in the logic it wraps.
9. Declare variables close to where they're used — don't declare everything at the top of a function regardless of when it's needed.

## Anti-patterns

- Single/double-letter or abbreviated variable names (`d`, `usrCnt`, `genymdhms`) outside of a genuinely tiny, obvious loop index.
- A function over ~20-30 lines doing several distinct things — a strong signal it should be several functions.
- A comment restating what the next line already says (`// increment i` above `i++`).
- `getFoo()` returning `null` on "not found" instead of `Optional.empty()` — pushes a null-check obligation onto every caller, and the one caller who forgets it gets an NPE in production.
- Magic numbers/strings with no named constant explaining what they mean.
- A class named `...Manager`/`...Helper`/`...Util` that has quietly become a dumping ground for unrelated logic.

## Examples

**Do this:**
```java
if (employee.isEligibleForFullBenefits()) { ... }
```

**Not this:**
```java
// Check if employee is eligible for full benefits
if (employee.flags & HOURLY == 0 && employee.age > 65) { ... }
```

**Do this:**
```java
Optional<Customer> findByEmail(String email);
```

**Not this:**
```java
Customer findByEmail(String email); // returns null if not found — every caller must remember to check
```
