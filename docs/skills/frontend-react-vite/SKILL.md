---
name: frontend-react-vite
description: "React + Vite conventions: server-state libraries, schema-validated boundaries, code-splitting, public env vars"
---

# Frontend (React + Vite)


## Rules

1. Use a server-state library (e.g. `@tanstack/react-query`) for anything fetched from an API — never a bare `useEffect` + `fetch`/`axios` call.
2. Keep client-only state (UI toggles, form-in-progress state, etc.) in the client store (e.g. Zustand); never put server-fetched data there — the query cache already owns it.
3. Lazy-load route-level components; never bundle every page into the initial chunk.
4. Validate and parse external input at the boundary — form input and API responses — with a schema library (e.g. Zod). Never trust a `fetch` response's shape without validating it.
5. Never use `any`. At an API boundary, type the response as `unknown` and narrow it via the schema/type guard from Rule 4.
6. Every `VITE_*` env var is public — it is baked into the built JS bundle and is readable by anyone who opens the app. Never put a secret, API key, or token in a `VITE_*` var; secrets belong server-side only, injected at the API layer.
7. Use a path alias (e.g. `@/`) for cross-directory imports; never write a relative import more than two `../` segments deep.
8. Whatever serves the built SPA (nginx, a CDN, a Node static server) must fall back unknown paths to `index.html` — a hard refresh or direct link on a client-side route must not 404.
9. Split vendor/framework code into its own bundle chunk (e.g. via `manualChunks`) — never ship one monolithic JS bundle mixing app code and third-party libraries.
10. Serve built static assets (JS/CSS/images with content-hashed filenames) with long-lived, immutable cache headers; never apply that same long-lived caching to `index.html` itself.

## Anti-patterns

- `useEffect(() => { fetch(url).then(setState) }, [])` for server data — no caching, no request dedupe, no automatic revalidation, and every consuming component re-fetches independently.
- Storing a fetched list/entity in a Zustand/Redux store "for convenience" — it silently goes stale the moment the server data changes elsewhere, since nothing invalidates it.
- Reading a secret via `import.meta.env.VITE_SOME_KEY` believing it stays server-side — it does not; grep the built `dist/` bundle and it's right there in plaintext.
- `import Button from '../../../../components/ui/Button'` instead of `import Button from '@/components/ui/Button'`.
- Missing SPA fallback routing in whatever hosts the build — works fine navigating client-side, 404s on refresh or a shared deep link.
- One giant bundle with no code-splitting — every route pays the download cost of every other route.

## Examples

**Server state — do this:**
```typescript
function useReservation(id: string) {
  return useQuery({
    queryKey: ['reservation', id],
    queryFn: () => api.get(`/reservations/${id}`).then(parseReservation),
  });
}
```

**Not this:**
```typescript
const [reservation, setReservation] = useState(null);
useEffect(() => {
  fetch(`/api/reservations/${id}`).then(r => r.json()).then(setReservation);
}, [id]);
```

**API boundary validation — do this:**
```typescript
const ReservationSchema = z.object({ id: z.string(), status: z.enum(['pending', 'confirmed']) });
const parseReservation = (data: unknown) => ReservationSchema.parse(data);
```

**Env vars — do this:**
```typescript
// src/lib/config.ts — only ever reference VITE_* here, never inline elsewhere
export const config = {
  apiBaseUrl: import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:8080',
} as const;
```
```text
# .env.nonprod — fine to commit, no secrets
VITE_API_BASE_URL=https://api.nonprod.myapp.com
```
Never: `VITE_STRIPE_SECRET_KEY=sk_live_...` — anything prefixed `VITE_` ships to every browser that loads the app.
