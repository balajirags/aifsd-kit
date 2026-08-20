---
name: code-review
description: How to perform structured code reviews for Java Spring Boot projects with prioritized checklists for security, architecture, quality, and testing.
---

# Code Review Skill (Java Spring Boot)

> Purpose: Provide a structured, prioritized code review process for Java Spring Boot projects with DDD/CQRS patterns.

---

## Review Workflow

### 1. Initial Analysis

- Read changed files to understand scope
- Check for related test files
- Review git changes/diffs
- Identify architectural patterns used
- Scan for potential security implications

### 2. Systematic Review (by priority)

#### Priority 1: Security & Critical Issues

- [ ] **Input Validation**: All user inputs properly validated and sanitized
- [ ] **SQL Injection**: JPA queries use parameterized statements
- [ ] **Authentication/Authorization**: Proper OAuth2 JWT validation, scope checks
- [ ] **Sensitive Data**: No secrets, credentials, or PII in logs/responses
- [ ] **Headers**: Required headers validated

#### Priority 2: Architectural Compliance

- [ ] **DDD Patterns**: Entities contain domain logic, validators enforce policies
- [ ] **CQRS Commands**: Complex operations use command pattern
- [ ] **Validation Layers**: Input → Business → Domain validation hierarchy maintained
- [ ] **Separation of Concerns**: Controllers delegate, services orchestrate, repositories persist

#### Priority 3: Code Quality & Design Principles

- [ ] **Clean Code**: Self-documenting code with meaningful names, small functions, clear intent
- [ ] **DRY**: No code duplication, shared logic properly abstracted
- [ ] **YAGNI**: No over-engineering, premature optimization, or unused features
- [ ] **SOLID Principles**:
  - Single Responsibility: Classes/functions have one reason to change
  - Open/Closed: Open for extension, closed for modification
  - Liskov Substitution: Subtypes must be substitutable for base types
  - Interface Segregation: Clients shouldn't depend on unused interfaces
  - Dependency Inversion: Depend on abstractions, not concretions
- [ ] **KISS**: Simple solutions over complex ones
- [ ] **Spring Boot**: Correct annotations, configuration, dependency injection
- [ ] **Error Handling**: Custom exceptions with structured error codes
- [ ] **Database**: JSONB for metadata, lazy loading, proper entity relationships
- [ ] **Naming**: Tables plural, entities singular with `Entity` suffix

#### Priority 4: Testing & Documentation

- [ ] **Test Coverage**: Unit tests with JUnit 5/Mockito/AssertJ
- [ ] **Integration Tests**: `@SpringBootTest` with TestContainers when needed
- [ ] **Mocking**: Mockito for dependencies
- [ ] **Documentation**: Clear comments for complex business logic
- [ ] **API Changes**: OpenAPI spec updated if endpoints modified

---

## Review Output Format

```markdown
## Code Review Summary
**Files Reviewed**: [count] | **Issues Found**: [count] | **Severity**: [High/Medium/Low]

### Critical Issues (Fix Required)
- [Specific issue with file:line reference]
- [Actionable fix suggestion]

### Important Issues (Should Fix)
- [Issue description]
- [Recommended approach]

### Suggestions (Consider)
- [Enhancement opportunity]
- [Best practice recommendation]

### Positive Observations
- [Good patterns followed]
- [Quality improvements made]
```

---

## Common Anti-Patterns to Flag

### Architectural

- Domain logic in validators (use entity methods for "CAN", validators for "SHOULD")
- Bypassing validation framework
- Direct JPA `save()` without service layer validation
- Network IO in repositories

### Design Principle Violations

- **DRY**: Duplicated validation, error handling, or business logic
- **YAGNI**: Over-engineered abstractions, unused parameters, "future-proof" code
- **SRP**: Classes doing multiple things (e.g., validation + persistence + formatting)
- **Large Functions**: Methods over 30 lines that do multiple things
- **Magic Numbers**: Hardcoded constants without explanation
- **Poor Naming**: Abbreviations, misleading names, non-descriptive variables
- **Comment Smells**: Comments explaining obvious code instead of business rules

---

## Performance Considerations

- Database queries optimized (avoid N+1 problems)
- Lazy loading used appropriately
- Large file operations use streaming
- Caching strategies applied where beneficial

---

## Review Principles

- Be thorough but constructive
- Focus on education and improvement, not just finding problems
- Prioritize issues by severity and impact
- Provide actionable feedback with specific file:line references
- Acknowledge good practices to reinforce positive patterns
