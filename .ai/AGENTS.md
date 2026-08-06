# Practica Stack — AI Council (portafolio)

> Comité de expertos para el stack de estudio (ms-auth · practica · ms-frontend).  
> **Lecciones Kilele aplicadas:** unit/API verde ≠ PASS visual · nav cliente ≠ AuthZ servidor · reset sin password en claro · rebuild Docker antes de declarar “no hay UI” · no inventar métricas.

## Roster (fan-out obligatorio)

| Rol | Especialidad | Ficha | Skills Cursor |
|-----|--------------|-------|---------------|
| **Security / AuthZ** | JWT, RBAC, AD sim, OWASP | `ms-auth/.ai/SECURITY.md` + `ACTIVE-DIRECTORY.md` | reviewer / security-review |
| **Spring Backend** | Boot 2.7, MockMvc, Flyway, JaCoCo | `ms-auth/.ai/SPRINGBOOT.md` + `QA.md` | reviewer |
| **React / Vite** | SPA, i18n es-CO/en, Vitest | `ms-frontend/.ai/REACT.md` | reviewer |
| **UX / Design** | Jerarquía, discoverability, estados OK/DENY | `ms-frontend/.ai/DESIGN.md` | reviewer |
| **QA Director** | JUnit + Playwright + honestidad de claims | este archivo §Gates + `ms-auth/.ai/QA.md` | shell |
| **DevOps** | Compose, images stale, health | `practica-stack/README.md` | shell |

## Gates (Kilele-inspired)

Antes de declarar **módulo AuthZ OK / demo OK**:

1. **Discover** — ¿imagen Docker = código local? (`docker compose up --build`)
2. **API** — `mvnw -Dtest=RbacControllerIntegrationTest test` (seller 403 precio/stock)
3. **Visual E2E** — `npx playwright test tests/e2e/rbac-module-authz.spec.js --workers=1`
4. **Claims** — login hint y docs no prometen LDAP real ni “cumple 100% AD”
5. **Docs sync** — `ACTIVE-DIRECTORY.md` + `docs/PORTFOLIO-STUDY-PATH.md`

**Prohibido:** “PASS” solo con Vitest/JUnit; “no veo Administración” sin verificar usuario=`admin` e imagen fresca.

## Formato scorecard por agente

```
VERDICT: APTO | APTO CONDICIONAL | NO APTO
Score: 0–10
DONE: (≤5)
OPEN: (≤5)
RISKS: (≤5)
TEST_GAPS: (casos concretos)
Evidence: paths / comandos
```

## Credenciales demo (solo stack/dev)

| User | Uso en validación |
|------|-------------------|
| admin / Admin123! | Administración → Permisos/Roles |
| seller / Seller123! | Inventario READ; WRITE → 403 |

## Estado consejo (2026-08-06)

- Veredicto: **APTO CONDICIONAL** — acta `docs/auditorias/COUNCIL-AUTHZ-2026-08-06.md`
- P2 cerrado (pragmático): `@Valid` inventario · Vitest AuthZ helpers · Flyway file gate · i18n Parámetros EN (smoke humano OK)
- `practica` sync: 403 AccessDenied + `ParametroAuthzIntegrationTest` (`f081c3e`)
- Repos: `ms-auth` · `ms-frontend` · `practica` · **este repo** (compose/council)
- Residual opcional: Flyway Testcontainers
- Demo: `docs/PORTFOLIO-STUDY-PATH.md`

## Cómo invocar el consejo

En Cursor: pedir «valida con el consejo Practica» → fan-out Security + Spring + React/UX + Playwright/DevOps en paralelo → síntesis con veredicto global.
