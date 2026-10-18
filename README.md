# StructFlow

StructFlow is a Flutter construction project-management application and an
early multi-tenant backend foundation. The Flutter client includes project,
task, team, calendar, document, attendance, and user-management screens. The
separate Dart API provides PostgreSQL-backed authentication, organization
membership, project access, task reading and creation, and audit events.

## Run the Flutter client

Requirements: Flutter SDK compatible with the Dart constraint in `pubspec.yaml`.

```powershell
flutter pub get
flutter run
```

Run client checks:

```powershell
flutter analyze
flutter test
```

## Run the API locally

See [backend/README.md](./backend/README.md) for PostgreSQL setup, migrations,
local API configuration, and the initial API endpoints.

See [docs/product-roadmap.md](./docs/product-roadmap.md) for the ordered
100-step enterprise development roadmap and current readiness boundaries.

Run backend checks:

```powershell
Set-Location backend
dart pub get
dart analyze
dart test
```

## Product and security status

**StructFlow is not ready for production or real company data.** The Flutter
client is only partially migrated to the API and continues to use local demo
repositories for most features. The backend is an initial foundation—not a
complete product or security certification. Self-service organization signup is intentionally
disabled in production until verified invitations/onboarding exist. Flutter
release builds are currently blocked with a readiness screen so the local
plaintext-password demo cannot be shipped accidentally.

Do not use the current Flutter client to store real employee credentials,
attendance records, commercial documents, project budgets, or customer
information. Production readiness also requires migrating every feature to
tenant-scoped server APIs, email verification and invitations, password
recovery, MFA/SSO, distributed rate limiting, role/project administration,
integration tests for tenant isolation, deployment secret management, backups,
monitoring, and operational recovery procedures.

Development API authentication can be enabled with
`--dart-define=STRUCTFLOW_API_BASE_URL=https://your-api-host`; it stores only
the session token in platform secure storage. After login the company-scoped
project list is loaded from the API, and company owners/admins can create
projects with client, type, budget/currency, and planned schedule metadata.
Project details are also fetched from the server; owners/admins can edit
project metadata with stale-version conflict protection. Project task lists are
loaded from the tenant-scoped API, and permitted users can create unassigned
tasks through the API. Assigned project managers and company owners/admins can
edit task details through version-checked API updates. Task assignment is not
connected yet.
Other unfinished modules remain unavailable in API mode.
See
[backend/README.md](./backend/README.md) for details.
