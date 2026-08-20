---
name: containerization-docker
description: "Multi-stage, pinned, non-root Dockerfile conventions for reproducible minimal runtime images"
---

# Containerization (Docker)

> Adapted from `.agents/skills/multi-stage-dockerfile/SKILL.md`.

## Rules

1. Use a multi-stage build: a builder stage for compiling/installing dependencies, and a separate, minimal runtime stage that copies over only the built artifact — never ship build tools or source in the final image.
2. Pin exact base-image version tags (e.g. `eclipse-temurin:21-jre-alpine`, not `eclipse-temurin:latest`) — a floating tag breaks reproducible builds.
3. Order Dockerfile instructions from least- to most-frequently-changing (dependency manifests and install before app source) so the dependency layer stays cached across code-only changes.
4. Run the container as a non-root user (`USER` instruction) — never leave the final image running as root.
5. Add a `.dockerignore` covering at minimum: `.git`, `node_modules`/build output, local env files, and test artifacts — never let the build context pull in files the image doesn't need.
6. Never bake a secret into an image layer (including build args that leak into the final image) — pass secrets at runtime (env var, mounted secret) or via a build-time secret mount that isn't persisted in a layer.
7. Combine related `RUN` commands with `&&` where they represent one logical step — don't split "install deps" across five separate `RUN` layers that each embed the removed intermediate state.
8. Add a `HEALTHCHECK` (or equivalent readiness probe wiring) appropriate to the app type — an orchestrator needs a real signal, not just "the process didn't crash."

## Anti-patterns

- `FROM node:latest` (or any unpinned tag) — the same Dockerfile can build a different image tomorrow.
- Copying the entire repo (`COPY . .`) before installing dependencies — invalidates the dependency-layer cache on every source change.
- `ARG API_KEY` baked into a `RUN` step in the final stage — it's recoverable from the image layer history even if the final `ENV` doesn't show it.
- A single-stage Dockerfile that ships the compiler/SDK/dev dependencies into production — larger attack surface, larger image, slower deploys.
- Running as root "because it was easier to get working" — a container escape or RCE now has root inside (and potentially outside) the container.

## Examples

**Multi-stage, non-root, cached dependency layer (Java/Gradle):**
```dockerfile
FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /app
COPY build.gradle settings.gradle ./
COPY gradle ./gradle
RUN ./gradlew dependencies --no-daemon
COPY src ./src
RUN ./gradlew bootJar --no-daemon

FROM eclipse-temurin:21-jre-alpine AS release
RUN addgroup -S app && adduser -S app -G app
WORKDIR /app
COPY --from=build --chown=app:app /app/build/libs/*.jar app.jar
USER app
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:8080/actuator/health || exit 1
ENTRYPOINT ["java", "-jar", "app.jar"]
```
