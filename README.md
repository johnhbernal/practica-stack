# practica-stack

Docker Compose for the full Practica learning stack:

| Service | Host port | Notes |
|---------|-----------|--------|
| `postgres` | 5432 | DBs `msauth` + `practica` |
| `ms-auth` | 8081 | profiles `prod,stack` (Flyway + seed users) |
| `microservicio-practica` | 8082 | context `/api`, profiles `prod,stack` |
| `ms-frontend` | 3000 | nginx SPA → container 8080 |

## Layout (required)

```
C:\Proyectos\
  ms-auth\          # https://github.com/johnhbernal/ms-auth
  practica\         # https://github.com/johnhbernal/practica
  ms-frontend\      # https://github.com/johnhbernal/ms-frontend
  practica-stack\   # this repo (compose + council docs; builds siblings)
```

GitHub (after push): `https://github.com/johnhbernal/practica-stack`

## Prerequisites

1. **Docker Desktop** for Windows (WSL2 backend recommended)  
   `winget install -e --id Docker.DockerDesktop` → start Docker → wait until engine is running.
2. Sibling repos cloned next to this folder (see layout).

## Quick start (Docker)

```powershell
cd C:\Proyectos\practica-stack
copy .env.example .env
powershell -File scripts\smoke-stack-docker.ps1
# or: docker compose up --build
```

Open **http://localhost:3000** — login `admin` / `Admin123!`

Health:

- http://localhost:8081/actuator/health  
- http://localhost:8082/api/actuator/health  
- http://localhost:3000/health  

Stop: `docker compose down` (add `-v` to wipe Postgres volume).

## Without Docker (local JVM/Node)

```powershell
powershell -File scripts\smoke-stack-local.ps1
```

Uses each service’s **dev** profile (H2) + `npm run dev`. Prefer Docker for prod-like Postgres/Flyway.

## JWT secrets

`.env` secrets must match across auth and practica (≥ 32 chars).  
Feign: auth uses `MS_PRACTICA_URL=http://microservicio-practica:8082` (client appends `/api`).

## Seed users (`stack` profile)

| User | Password | Role | Demo |
|------|----------|------|------|
| admin | Admin123! | ADMIN | Full RBAC + inventario write |
| user | User123! | USER | Parámetros |
| reader | Read123! | READONLY | Parámetros read |
| seller | Seller123! | USER (group VENDEDOR) | Inventario: **read prices only** (403 on price/stock write) |

Only when profile includes `stack` or `dev` — **never** enable `stack` in real production.

### Portfolio study path

1. Login as `admin` → **Administración** → create permissions by **module**, roles, AD-sim groups.
2. Login as `seller` → **Inventario** → see prices; buttons for price/stock stay disabled / API returns 403.
3. Switch language **es-CO / English** in the shell.
4. Forgot password → one-time token (logged by ms-auth in stack; never emails plaintext password).

Detail: `ms-auth/.ai/ACTIVE-DIRECTORY.md` · study path: [`docs/PORTFOLIO-STUDY-PATH.md`](docs/PORTFOLIO-STUDY-PATH.md).

**If you do not see Administration:** you are on an old image or not logged as `admin`. Rebuild:

```powershell
docker compose up --build -d --force-recreate ms-auth ms-frontend
# then Ctrl+F5 in the browser
```

## Frontend env (Vite)

Build-time vars for `ms-frontend` Docker image: `VITE_AUTH_API_URL`, `VITE_PRACTICA_API_URL` (see `../ms-frontend/.env.example`).
