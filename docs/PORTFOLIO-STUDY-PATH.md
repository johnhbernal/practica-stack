# Portfolio study path — AuthN / AuthZ / AD sim

Use this after `docker compose up --build` (or local JVM) with the **current** sibling repos.

**Repos (2026-08-06):** `ms-auth` · `ms-frontend` · `practica` pushed with RBAC + i18n + 403 AuthZ.  
Council acta: [`auditorias/COUNCIL-AUTHZ-2026-08-06.md`](auditorias/COUNCIL-AUTHZ-2026-08-06.md).

## Why you might not see “Administración”

| Symptom | Cause | Fix |
|---------|-------|-----|
| Sidebar has no **Administración** | Logged in as `user` / `reader` / `seller` | Login as **`admin` / `Admin123!`** |
| Login UI says “MS Practica” / “Ingresar”, no language switcher | Old Docker image of `ms-frontend` | Rebuild: `docker compose up --build -d ms-frontend` |
| JWT has only `role` (no `permissions` / `groups`) | Old `ms-auth` image | Rebuild + recreate `ms-auth` |
| `GET /api/rbac/permissions` → 404 | Same — RBAC not in running binary | Rebuild `ms-auth` from local source |
| `seller` login 401 | Seed not applied (old image / no `stack` profile) | Profiles `prod,stack` + recreate container |
| Language → English but Parámetros still Spanish | Old frontend without i18n on home | Rebuild `ms-frontend` + Ctrl+F5 |

Hard refresh the browser (`Ctrl+F5`) after rebuild.

## Demo script (≈10 min)

| Step | Action | What you prove |
|------|--------|----------------|
| 1 | Login `admin` / `Admin123!` | AuthN + seed `stack` |
| 2 | **Administración** → Permisos (module INVENTARIO) | RBAC admin API/UI |
| 3 | Language → **English** | i18n (System parameters, nav) |
| 4 | Logout → `seller` / `Seller123!` → **Inventario** | READ OK; WRITE DENY + API **403** |
| 5 | Same seller → Parámetros: can open activos path; cannot admin-list-all | `practica` AuthZ = primary `role` (not `permissions[]`) |
| 6 | Forgot password (optional) | One-time token; never plaintext email |

## Demo credentials

| User | Password | What to show |
|------|----------|--------------|
| admin | Admin123! | **Administración** → Usuarios / Grupos / Roles / **Permisos** |
| seller | Seller123! | **Inventario** — prices visible; save disabled; PUT **403** |
| user | User123! | Parámetros (no admin nav) |

## Talking points (interviews)

1. **AuthN** — BCrypt login → session JWT (15 min) + renew; logout rotates `sessionUuid`.
2. **AuthZ** — `User → DirectoryGroup → AppRole → Permission(module)` → JWT `permissions[]` → Spring `PERM_*` (**ms-auth**).
3. **Module matrix** — `VENDEDOR` has `INVENTARIO_PRECIO_READ` only (not WRITE).
4. **Boundary** — `practica` validates JWT + `hasRole('ADMIN')` for writes; ignores `permissions[]` by design.
5. **AD simulation** — groups with DN; mode `APP_AUTH_MODE=directory` for bind logging (no real LDAP).
6. **Password reset** — one-time token; never email plaintext password.
7. **Ops lesson** — unit green ≠ UI; stale Docker image looks like a product bug.

Detail: `ms-auth/.ai/ACTIVE-DIRECTORY.md` · council: `.ai/AGENTS.md`.

## Captures to keep (suggested)

1. Login with demo hint + language switcher.
2. Admin → Permisos tab (module badge + create form).
3. Seller → Inventario with WRITE badges DENY.
4. English Parámetros title (“System parameters”).
5. `/directory/me` for admin (groups / roles / permissions).

## Evidence commands

```powershell
cd C:\Proyectos\practica-stack
powershell -File scripts\smoke-stack-docker.ps1

cd ..\ms-auth
.\mvnw.cmd -B "-Dtest=RbacControllerIntegrationTest,FlywayMigrationFilesTest" test

cd ..\practica
.\mvnw.cmd -B "-Dtest=ParametroAuthzIntegrationTest" test

cd ..\ms-frontend
npm run test:e2e:rbac
```
