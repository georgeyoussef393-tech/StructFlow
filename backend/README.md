# StructFlow API foundation

This Dart/Shelf service is the first backend slice for StructFlow. It uses
PostgreSQL for users, organizations, memberships, sessions, projects, and
append-only audit events.

## Local development

Requirements: Dart SDK `^3.12.0` and PostgreSQL 17 (Docker Compose is optional).

From the repository root, start a development database:

```powershell
Copy-Item backend\.env.example backend\.env
# Edit backend\.env and replace the local-only placeholder password.
docker compose --env-file backend\.env -f backend\docker-compose.yml up -d
```

Apply the initial schema as the local database administrator:

```powershell
Get-Content backend\migrations\001_initial.sql -Raw | docker compose --env-file backend\.env -f backend\docker-compose.yml exec -T postgres psql -U structflow_admin -d structflow
```

For local development only, use the administrator connection and start the
server:

```powershell
$env:POSTGRES_PASSWORD = "the-same-value-you-set-in-backend.env"
$env:DATABASE_URL = "postgresql://structflow_admin:$env:POSTGRES_PASSWORD@localhost:5432/structflow"
$env:ENABLE_ORGANIZATION_SIGNUP = "true"
Set-Location backend
dart pub get
dart run bin/server.dart
```

The local-only example uses the database administrator role for convenience.
Production must use a dedicated restricted database role, a secret manager,
and `sslmode=verify-full`.

## API slice

- `GET /healthz`: checks database connectivity without exposing database data.
- `POST /v1/auth/organizations`: development-only organization bootstrap.
- `POST /v1/auth/login`: verifies bcrypt password hashes and returns an opaque
  eight-hour bearer session.
- `POST /v1/auth/logout`: revokes the current session.
- `GET /v1/me`: returns the authenticated user and active memberships.
- `GET /v1/projects`: returns organization-wide projects to owners/admins and
  only assigned projects to other members.
- `GET /v1/projects/{projectId}`: returns one project only when it belongs to
  the active organization and the caller has organization-wide or explicit
  project access. The route accepts a project code for compatibility; projects
  that are inaccessible or nonexistent return the same `404`.
- `POST /v1/projects`: creates projects for owners/admins only.
- `PATCH /v1/projects/{projectId}`: updates project metadata for owners/admins
  only, using `expectedVersion` for optimistic concurrency.
- `GET /v1/tasks`: returns tasks scoped to projects accessible to the caller;
  accepts an optional `projectCode` filter.
- `POST /v1/tasks`: creates unassigned tasks in `To Do` status for organization
  owners/admins or an assigned project manager; project membership is checked
  server-side and task creation is recorded in the audit log.
- `GET /v1/tasks/{taskId}`: returns one task within the active company scope.
- `PATCH /v1/tasks/{taskId}`: updates task text, status, priority, due date, and
  progress for owners/admins or the assigned project manager. Updates require
  `expectedVersion`, return `409` on conflicts, and are audited.

For development, point the Flutter sign-in screen at the API with
`flutter run --dart-define=STRUCTFLOW_API_BASE_URL=https://api.example.test`.
Do not use a production customer identity provider or customer account for this
development-only client integration.
The client stores only the opaque API session token using platform secure
storage; it never persists the submitted password. Use HTTPS outside loopback
development. If the account has more than one organization, sign-in is refused
until company selection is implemented.

Successful API authentication leads to a company project list backed by
`GET /v1/projects`. Owners/admins can create projects through
`POST /v1/projects`, including client, type, budget/currency, and planned
dates. The API validates metadata and the database enforces date ordering.
Project details are read from the API with tenant and project membership checks.
Owners/admins can update project metadata through `PATCH /v1/projects/{id}`.
Updates require the current project version and return `409` when another user
has already changed it. Restricted column grants and an owner/admin-only RLS
policy backstop the API permission check. Task lists, details, creation, and basic updates are connected to the API, but
task assignment, documents, workforce, and attendance endpoints are not
available; their local demo data is intentionally not loaded for API-authenticated
accounts.

Every organization-scoped request must send `X-Organization-ID`; the server
validates it against the bearer session's active membership. Tenant IDs and
roles supplied by the client are never treated as proof of access. Session
tokens are random and only their SHA-256 digests are stored. Password hashing
and verification run in isolates to avoid blocking the request event loop.
Project, project-assignment, and audit tables also use PostgreSQL row-level
security with transaction-local organization and user context. These policies
are defense in depth; they do not make a compromised API/database credential
safe. The current schema does not yet apply RLS to global identity, organization,
membership, or session tables; callers must use the API's validated query paths,
and these tables require additional hardening before production deployment.

## Not production-ready yet

This is a foundation, not a complete production service. Organization bootstrap
is deliberately disabled in production; verified invitations, email delivery,
password recovery, MFA/SSO, account lockout, distributed edge rate limiting,
organization administration, project assignment workflows, and APIs for tasks,
documents, attendance, and the remaining Flutter modules are still required.
The current Flutter application has not been migrated to this API and continues
to use local demo repositories. Do not enter real customer credentials or
business data into that client yet.

Before deployment, apply migrations with a controlled migration account, use
the restricted runtime grants in `migrations/README.md`, terminate TLS at a
trusted ingress, configure distributed request throttling and monitoring, and
run integration tests against a dedicated disposable PostgreSQL database.
