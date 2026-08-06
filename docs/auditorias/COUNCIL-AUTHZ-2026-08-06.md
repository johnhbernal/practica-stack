# Council AuthZ — 2026-08-06

Comité Practica (lecciones Kilele). Fan-out: Security · Spring · React/UX · Playwright/DevOps.

## Veredicto global: **APTO CONDICIONAL**

| Agente | Link | Veredicto | Score | Nota |
|--------|------|-----------|-------|------|
| Security / AuthZ | [Security](7fcdc565-e1aa-4d2f-a20d-2ddf7d0488fc) | APTO CONDICIONAL | 8/10 | `@PreAuthorize` + reset hashed + `@Valid` inventario (post-P2) |
| Spring / Backend | [Spring](6fa748fd-77d3-432d-a880-e48fd4ddf8e4) | CONDITIONAL GO | 78/100 | Seller 403 + MODULE IT + Flyway file gate (Testcontainers deferred) |
| React / UX Design | [UX](f5b053dd-4765-42f3-992e-2b86a36027bf) | CONDITIONAL PASS | 85/100 | i18n Parámetros EN/ES + DENY badges + empty states |
| Playwright / DevOps | [E2E](0de6b03b-a4b0-4bed-baeb-dddad8f7400d) | PASS (revalidado) | 6/6 | Admin + seller 403 API; lead rebuild |

### Revalidación lead (post-comité + P2 + smoke humano)

| Check | Resultado |
|-------|-----------|
| `RbacControllerIntegrationTest` + `FlywayMigrationFilesTest` | **11/11 PASS** |
| Vitest (`hasPermission` / i18n / displayParamValue) | **13/13 PASS** |
| `npm run test:e2e:rbac` | **2/2 PASS** (sesión previa) |
| Smoke humano idioma EN (Parámetros/nav) | **PASS** (fundador 2026-08-06) |
| Stack Docker rebuild frontend | **PASS** |
| `practica` JWT AuthZ (role-only + docs sync) | **APTO CONDICIONAL** → `f081c3e` (403 AccessDenied + `ParametroAuthzIntegrationTest`) |

## Lecciones Kilele aplicadas

1. Unit/API ≠ visual PASS → E2E obligatorio (`--workers=1`).
2. Botón disabled ≠ AuthZ → Playwright afirma HTTP **403** en PUT.
3. “No veo Administración” → usuario `admin` + rebuild imagen (no inventar bug).
4. Reset password sin plaintext.
5. Claims honestos: AD **simulado**.
6. Switcher de idioma ≠ i18n completo → cablear home/modales a `t()`.

## Acciones del consejo (hechas)

- Fichas: `practica-stack/.ai/AGENTS.md`, `ms-auth/.ai/QA.md`, `ms-frontend/.ai/{QA,DESIGN}.md`
- Skill: `ms-frontend/.cursor/skills/practica-council`
- E2E endurecido: login wait URL + API 403
- UX: badges DENY → `danger` + i18n `badgeOk`/`badgeDeny`
- i18n: `ParametrosPage` / `ParametroModal` / `NotFoundPage` bilingüe

## Follow-up post-notificaciones (cerrado)

| Origen | Acción |
|--------|--------|
| [UX](f5b053dd-4765-42f3-992e-2b86a36027bf) | empty states + badge `danger` + E2E `.bg-danger` |
| [Spring](6fa748fd-77d3-432d-a880-e48fd4ddf8e4) | `syncVendedorPermissions` + V5 INVENTARIO MODULE + IT admin write / module assert |
| [E2E](0de6b03b-a4b0-4bed-baeb-dddad8f7400d) | rebuild frontend/auth + login waitURL; E2E revalidado |
| P2 Security | `@Valid` PriceUpdate/StockUpdate + IT 400 |
| P2 QA FE | Vitest `hasPermission` / `canSeeInventory` / `isAdminNavVisible` |
| P2 Flyway | `FlywayMigrationFilesTest` (sin Testcontainers; gate de archivos V4/V5) |
| i18n smoke | textos Parámetros cableados; smoke humano EN OK |

## OPEN residual

- [ ] Flyway IT con Testcontainers (opcional; H2 + file gate cubren P2 pragmático)
- [x] `@Valid` en DTOs inventario
- [x] Vitest `hasPermission` / `canSeeInventory`
- [x] Smoke humano i18n EN
- [x] Commit/push `ms-auth` / `ms-frontend` / `practica` (`f081c3e`)
- [x] Versionar `practica-stack` (compose + council + study path)

## Comandos

```powershell
cd C:\Proyectos\practica-stack
docker compose up --build -d --force-recreate ms-auth ms-frontend
cd C:\Proyectos\ms-auth
.\mvnw.cmd -B "-Dtest=RbacControllerIntegrationTest,FlywayMigrationFilesTest" test
cd C:\Proyectos\ms-frontend
npm test
npm run test:e2e:rbac
```
