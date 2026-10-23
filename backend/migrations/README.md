# Database migrations

Apply the numbered SQL migrations in order to a new PostgreSQL database using a dedicated
migration/owner account. The API runtime account should have only the privileges
needed for application tables and must not own the database or schema.

Create a separate `LOGIN` role through the cloud provider's secret-aware
administrative workflow, then apply `002_runtime_grants.sql` while connected
to the application database. Set its password outside source control and
grant that role `CONNECT` on the database.

```sql
CREATE ROLE structflow_runtime LOGIN NOSUPERUSER NOBYPASSRLS NOINHERIT;
\password structflow_runtime
\i backend/migrations/002_runtime_grants.sql
\i backend/migrations/003_project_metadata.sql
\i backend/migrations/004_project_update_access.sql
\i backend/migrations/005_project_tasks.sql
\i backend/migrations/006_task_creation_access.sql
\i backend/migrations/007_task_update_access.sql
\i backend/migrations/008_task_assignment.sql
\i backend/migrations/009_bim_issues.sql
\i backend/migrations/010_bim_models.sql
\i backend/migrations/011_bim_model_lifecycle.sql
\i backend/migrations/012_bim_issue_comments.sql
\i backend/migrations/013_bcf_comment_exchange.sql
```

Migrations are intentionally SQL files and should be reviewed and applied by a
controlled deployment process. Do not run schema migrations automatically from
every API instance at startup.
