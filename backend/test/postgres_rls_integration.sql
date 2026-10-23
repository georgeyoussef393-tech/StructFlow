\set ON_ERROR_STOP on

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM pg_roles
        WHERE rolname = 'structflow_runtime'
          AND (rolsuper OR rolbypassrls)
    ) THEN
        RAISE EXCEPTION 'runtime role must not be superuser or bypass RLS';
    END IF;
    IF NOT has_column_privilege(
        'structflow_runtime', 'projects', 'name', 'UPDATE'
    ) OR NOT has_column_privilege(
        'structflow_runtime', 'projects', 'version', 'UPDATE'
    ) THEN
        RAISE EXCEPTION 'runtime role is missing approved project update grants';
    END IF;
    IF has_column_privilege(
        'structflow_runtime', 'projects', 'code', 'UPDATE'
    ) OR has_column_privilege(
        'structflow_runtime', 'projects', 'organization_id', 'UPDATE'
    ) THEN
        RAISE EXCEPTION 'runtime role has unsafe project update grants';
    END IF;
    IF NOT has_table_privilege(
        'structflow_runtime', 'tasks', 'SELECT'
    ) OR NOT has_column_privilege(
        'structflow_runtime', 'tasks', 'title', 'INSERT'
    ) OR has_column_privilege(
        'structflow_runtime', 'tasks', 'version', 'INSERT'
    ) OR NOT has_column_privilege(
        'structflow_runtime', 'tasks', 'title', 'UPDATE'
    ) OR NOT has_column_privilege(
        'structflow_runtime', 'tasks', 'version', 'UPDATE'
    ) OR NOT has_column_privilege(
        'structflow_runtime', 'tasks', 'assigned_user_id', 'INSERT'
    ) OR NOT has_column_privilege(
        'structflow_runtime', 'tasks', 'assigned_user_id', 'UPDATE'
    ) OR has_column_privilege(
        'structflow_runtime', 'tasks', 'project_id', 'UPDATE'
    ) OR has_table_privilege(
        'structflow_runtime', 'tasks', 'UPDATE'
    ) THEN
        RAISE EXCEPTION 'runtime role has unexpected task permissions';
    END IF;
    IF has_table_privilege(
        'structflow_runtime', 'project_manager_scopes', 'SELECT'
    ) OR NOT has_function_privilege(
        'structflow_runtime',
        'app_is_active_project_manager(uuid, uuid)',
        'EXECUTE'
    ) THEN
        RAISE EXCEPTION 'project manager scope helper is not safely exposed';
    END IF;
    IF NOT has_table_privilege(
        'structflow_runtime', 'bim_issues', 'SELECT'
    ) OR NOT has_column_privilege(
        'structflow_runtime', 'bim_issues', 'title', 'INSERT'
    ) OR has_column_privilege(
        'structflow_runtime', 'bim_issues', 'version', 'INSERT'
    ) OR NOT has_column_privilege(
        'structflow_runtime', 'bim_issues', 'status', 'UPDATE'
    ) OR NOT has_column_privilege(
        'structflow_runtime', 'bim_issues', 'version', 'UPDATE'
    ) OR has_column_privilege(
        'structflow_runtime', 'bim_issues', 'bcf_guid', 'UPDATE'
    ) OR has_table_privilege(
        'structflow_runtime', 'bim_issues', 'UPDATE'
    ) THEN
        RAISE EXCEPTION 'runtime role has unexpected BIM issue permissions';
    END IF;
    IF NOT has_table_privilege(
        'structflow_runtime', 'bim_models', 'SELECT'
    ) OR NOT has_column_privilege(
        'structflow_runtime', 'bim_models', 'name', 'INSERT'
    ) OR has_column_privilege(
        'structflow_runtime', 'bim_models', 'status', 'INSERT'
    ) OR NOT has_column_privilege(
        'structflow_runtime', 'bim_models', 'status', 'UPDATE'
    ) OR NOT has_column_privilege(
        'structflow_runtime', 'bim_models', 'version', 'UPDATE'
    ) OR has_column_privilege(
        'structflow_runtime', 'bim_models', 'name', 'UPDATE'
    ) OR has_table_privilege(
        'structflow_runtime', 'bim_models', 'UPDATE'
    ) THEN
        RAISE EXCEPTION 'runtime role has unexpected BIM model permissions';
    END IF;
    IF NOT has_table_privilege(
        'structflow_runtime', 'bim_issue_comments', 'SELECT'
    ) OR NOT has_column_privilege(
        'structflow_runtime', 'bim_issue_comments', 'body', 'INSERT'
    ) OR NOT has_column_privilege(
        'structflow_runtime', 'bim_issue_comments', 'source_guid', 'INSERT'
    ) OR NOT has_column_privilege(
        'structflow_runtime', 'bim_issue_comments', 'created_at', 'INSERT'
    ) OR NOT has_column_privilege(
        'structflow_runtime', 'bim_issue_comments', 'source_author', 'INSERT'
    ) OR has_table_privilege(
        'structflow_runtime', 'bim_issue_comments', 'UPDATE'
    ) OR has_table_privilege(
        'structflow_runtime', 'bim_issue_comments', 'DELETE'
    ) THEN
        RAISE EXCEPTION 'runtime role has unexpected BIM comment permissions';
    END IF;
END;
$$;

INSERT INTO organizations (id, name, slug)
VALUES
    ('10000000-0000-4000-8000-000000000001', 'Tenant One', 'tenant-one-test'),
    ('10000000-0000-4000-8000-000000000002', 'Tenant Two', 'tenant-two-test');

INSERT INTO users (id, full_name, email, password_hash)
VALUES
    ('20000000-0000-4000-8000-000000000001', 'Tenant One User', 'one@test.invalid', 'test-hash'),
    ('20000000-0000-4000-8000-000000000002', 'Tenant Two User', 'two@test.invalid', 'test-hash'),
    ('20000000-0000-4000-8000-000000000003', 'Project Contributor', 'contributor@test.invalid', 'test-hash'),
    ('20000000-0000-4000-8000-000000000004', 'Project Viewer', 'viewer@test.invalid', 'test-hash');

INSERT INTO memberships (organization_id, user_id, role)
VALUES
    ('10000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', 'member'),
    ('10000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000003', 'member'),
    ('10000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000004', 'member'),
    ('10000000-0000-4000-8000-000000000002', '20000000-0000-4000-8000-000000000002', 'member');

INSERT INTO projects (
    id, organization_id, code, name, created_by, client_name, project_type,
    budget_amount, budget_currency, planned_start_date, planned_end_date
)
VALUES
    ('30000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'ONE', 'Tenant One Project', '20000000-0000-4000-8000-000000000001', 'Transit Authority', 'Infrastructure', 1250000.00, 'EGP', '2026-01-01', '2027-01-01'),
    ('30000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000002', 'TWO', 'Tenant Two Project', '20000000-0000-4000-8000-000000000002');

DO $$
BEGIN
    BEGIN
        INSERT INTO projects (
            organization_id, code, name, created_by,
            planned_start_date, planned_end_date
        )
        VALUES (
            '10000000-0000-4000-8000-000000000001',
            'INVALID-DATES', 'Invalid Dates',
            '20000000-0000-4000-8000-000000000001',
            '2027-01-02', '2027-01-01'
        );
        RAISE EXCEPTION 'projects unexpectedly accepted an end date before start date';
    EXCEPTION
        WHEN check_violation THEN NULL;
    END;
END;
$$;

INSERT INTO project_memberships (organization_id, project_id, user_id, role)
VALUES
    ('10000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', 'contributor'),
    ('10000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000003', 'contributor'),
    ('10000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000004', 'viewer');

INSERT INTO tasks (
    organization_id, project_id, title, due_date, created_by, assigned_user_id
)
VALUES
    ('10000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', 'Tenant One Task', '2027-02-01', '20000000-0000-4000-8000-000000000001'),
    ('10000000-0000-4000-8000-000000000002', '30000000-0000-4000-8000-000000000002', 'Tenant Two Task', '2027-02-01', '20000000-0000-4000-8000-000000000002');

BEGIN;
SET LOCAL ROLE structflow_runtime;
SELECT set_config('app.organization_id', '10000000-0000-4000-8000-000000000001', true);
SELECT set_config('app.user_id', '20000000-0000-4000-8000-000000000001', true);

DO $$
BEGIN
    IF (SELECT count(*) FROM projects) <> 1 THEN
        RAISE EXCEPTION 'tenant user must only see their own tenant project';
    END IF;
    IF EXISTS (SELECT 1 FROM projects WHERE organization_id = '10000000-0000-4000-8000-000000000002') THEN
        RAISE EXCEPTION 'tenant user can see another tenant project';
    END IF;
    IF (SELECT count(*) FROM project_memberships) <> 1 THEN
        RAISE EXCEPTION 'tenant user must only see their own project assignment';
    END IF;
    IF (SELECT count(*) FROM tasks) <> 1 OR NOT EXISTS (
        SELECT 1 FROM tasks t JOIN projects p
          ON p.organization_id = t.organization_id AND p.id = t.project_id
        WHERE t.title = 'Tenant One Task' AND p.code = 'ONE'
    ) THEN
        RAISE EXCEPTION 'tenant user must only see tasks in assigned projects';
    END IF;
    BEGIN
        INSERT INTO tasks (
            organization_id, project_id, title, due_date, created_by, assigned_user_id
        )
        VALUES (
            '10000000-0000-4000-8000-000000000001',
            '30000000-0000-4000-8000-000000000001',
            'Contributor cannot create tasks', '2027-02-02',
            '20000000-0000-4000-8000-000000000001'
        );
        RAISE EXCEPTION 'project contributor unexpectedly created a task';
    EXCEPTION
        WHEN insufficient_privilege THEN NULL;
    END;
    UPDATE tasks
    SET title = 'Contributor cannot update tasks', version = version + 1
    WHERE title = 'Tenant One Task';
    IF EXISTS (
        SELECT 1 FROM tasks WHERE title = 'Contributor cannot update tasks'
    ) THEN
        RAISE EXCEPTION 'project contributor unexpectedly updated a task';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM projects
        WHERE code = 'ONE'
          AND client_name = 'Transit Authority'
          AND project_type = 'Infrastructure'
          AND budget_amount = 1250000.00
          AND budget_currency = 'EGP'
          AND planned_start_date = '2026-01-01'
          AND planned_end_date = '2027-01-01'
          AND version = 1
    ) THEN
        RAISE EXCEPTION 'project metadata migration did not preserve supported project fields';
    END IF;
    UPDATE projects
    SET name = 'Unauthorized project edit'
    WHERE code = 'ONE';
    IF EXISTS (
        SELECT 1 FROM projects
        WHERE code = 'ONE' AND name = 'Unauthorized project edit'
    ) THEN
        RAISE EXCEPTION 'non-admin member unexpectedly updated a project';
    END IF;

    INSERT INTO audit_events (
        organization_id, actor_user_id, action, entity_type, entity_id
    )
    VALUES (
        '10000000-0000-4000-8000-000000000001',
        '20000000-0000-4000-8000-000000000001',
        'test.created', 'test', 'one'
    );

    BEGIN
        INSERT INTO audit_events (
            organization_id, actor_user_id, action, entity_type, entity_id
        )
        VALUES (
            '10000000-0000-4000-8000-000000000002',
            '20000000-0000-4000-8000-000000000002',
            'test.created', 'test', 'cross-tenant'
        );
        RAISE EXCEPTION 'runtime role unexpectedly wrote a cross-tenant audit event';
    EXCEPTION
        WHEN insufficient_privilege THEN NULL;
    END;

    BEGIN
        UPDATE audit_events SET metadata = '{"tampered": true}'::jsonb;
        RAISE EXCEPTION 'runtime role unexpectedly mutated an audit event';
    EXCEPTION
        WHEN insufficient_privilege THEN NULL;
    END;
END;
$$;
INSERT INTO bim_issues (
    organization_id, project_id, bcf_guid, title, description, discipline,
    location, severity, status, due_date, created_by
)
VALUES (
    '10000000-0000-4000-8000-000000000001',
    '30000000-0000-4000-8000-000000000001',
    '60000000-0000-4000-8000-000000000001',
    'Contributor-created coordination issue', '',
    'Architecture', 'Level 1', 'high', 'open', '2027-02-01',
    '20000000-0000-4000-8000-000000000001'
);
INSERT INTO bim_models (
    organization_id, project_id, name, discipline, revision, created_by
)
VALUES (
    '10000000-0000-4000-8000-000000000001',
    '30000000-0000-4000-8000-000000000001',
    'Tenant One Structure Model', 'Structure', 'v2',
    '20000000-0000-4000-8000-000000000001'
);
INSERT INTO bim_issue_comments (
    organization_id, project_id, issue_id, body, created_by
)
SELECT organization_id, project_id, id,
       'Reviewed clearance at grid C-2.',
       '20000000-0000-4000-8000-000000000001'
FROM bim_issues
WHERE title = 'Contributor-created coordination issue';
DO $$
DECLARE
    updated_rows integer;
BEGIN
    UPDATE bim_issues
    SET status = 'resolved', version = version + 1, updated_at = now()
    WHERE title = 'Contributor-created coordination issue';
    GET DIAGNOSTICS updated_rows = ROW_COUNT;
    IF updated_rows <> 0 THEN
        RAISE EXCEPTION 'project contributor unexpectedly updated a BIM issue';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM bim_issues
        WHERE title = 'Contributor-created coordination issue'
          AND status = 'open' AND version = 1
    ) THEN
        RAISE EXCEPTION 'project contributor changed a protected BIM issue';
    END IF;
    IF (SELECT count(*) FROM bim_models) <> 1 THEN
        RAISE EXCEPTION 'project contributor should see project BIM models';
    END IF;
    IF (SELECT count(*) FROM bim_issue_comments) <> 1 THEN
        RAISE EXCEPTION 'project contributor should see issue discussion';
    END IF;
    BEGIN
        UPDATE bim_models SET name = 'Contributor model update';
        RAISE EXCEPTION 'project contributor unexpectedly updated BIM model metadata';
    EXCEPTION
        WHEN insufficient_privilege THEN NULL;
    END;
    UPDATE bim_models
    SET status = 'published', version = version + 1, updated_at = now()
    WHERE name = 'Tenant One Structure Model';
    IF EXISTS (
        SELECT 1 FROM bim_models
        WHERE name = 'Tenant One Structure Model' AND status = 'published'
    ) THEN
        RAISE EXCEPTION 'project contributor unexpectedly changed BIM model status';
    END IF;
END;
$$;
SELECT set_config('app.user_id', '20000000-0000-4000-8000-000000000004', true);
DO $$
BEGIN
    IF (SELECT count(*) FROM bim_issues) <> 1 THEN
        RAISE EXCEPTION 'project viewer should be able to read BIM issues';
    END IF;
    IF (SELECT count(*) FROM bim_models) <> 1 THEN
        RAISE EXCEPTION 'project viewer should be able to read BIM models';
    END IF;
    IF (SELECT count(*) FROM bim_issue_comments) <> 1 THEN
        RAISE EXCEPTION 'project viewer should be able to read issue comments';
    END IF;
    BEGIN
        INSERT INTO bim_issues (
            organization_id, project_id, title, discipline, location,
            severity, due_date, created_by
        )
        VALUES (
            '10000000-0000-4000-8000-000000000001',
            '30000000-0000-4000-8000-000000000001',
            'Viewer-created coordination issue', 'Architecture', 'Level 2',
            'low', '2027-02-02',
            '20000000-0000-4000-8000-000000000004'
        );
        RAISE EXCEPTION 'project viewer unexpectedly created a BIM issue';
    EXCEPTION
        WHEN insufficient_privilege THEN NULL;
    END;
    BEGIN
        INSERT INTO bim_issue_comments (
            organization_id, project_id, issue_id, body, created_by
        )
        SELECT organization_id, project_id, id,
               'Viewer should not comment.',
               '20000000-0000-4000-8000-000000000004'
        FROM bim_issues
        WHERE title = 'Contributor-created coordination issue';
        RAISE EXCEPTION 'project viewer unexpectedly added an issue comment';
    EXCEPTION
        WHEN insufficient_privilege THEN NULL;
    END;
END;
$$;
SELECT set_config('app.organization_id', '10000000-0000-4000-8000-000000000002', true);
SELECT set_config('app.user_id', '20000000-0000-4000-8000-000000000002', true);
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM bim_issues) THEN
        RAISE EXCEPTION 'tenant user can see another tenant BIM issue';
    END IF;
    IF EXISTS (SELECT 1 FROM bim_models) THEN
        RAISE EXCEPTION 'tenant user can see another tenant BIM model';
    END IF;
    IF EXISTS (SELECT 1 FROM bim_issue_comments) THEN
        RAISE EXCEPTION 'tenant user can see another tenant BIM comment';
    END IF;
END;
$$;
COMMIT;

UPDATE project_memberships
SET role = 'project_manager'
WHERE organization_id = '10000000-0000-4000-8000-000000000001'
  AND project_id = '30000000-0000-4000-8000-000000000001'
  AND user_id = '20000000-0000-4000-8000-000000000001';

BEGIN;
SET LOCAL ROLE structflow_runtime;
SELECT set_config('app.organization_id', '10000000-0000-4000-8000-000000000001', true);
SELECT set_config('app.user_id', '20000000-0000-4000-8000-000000000001', true);
DO $$
BEGIN
    IF (SELECT count(*) FROM project_memberships) <> 3 THEN
        RAISE EXCEPTION 'assigned project manager should see only their project roster';
    END IF;
END;
$$;
DO $$
DECLARE
    updated_rows integer;
BEGIN
    UPDATE bim_issues
    SET status = 'resolved', version = version + 1, updated_at = now()
    WHERE title = 'Contributor-created coordination issue';
    GET DIAGNOSTICS updated_rows = ROW_COUNT;
    IF updated_rows <> 1 OR NOT EXISTS (
        SELECT 1 FROM bim_issues
        WHERE title = 'Contributor-created coordination issue'
          AND status = 'resolved' AND version = 2
    ) THEN
        RAISE EXCEPTION 'project manager should be allowed to update BIM issue status';
    END IF;
    UPDATE bim_models
    SET status = 'published', version = version + 1, updated_at = now()
    WHERE name = 'Tenant One Structure Model' AND version = 1;
    IF NOT EXISTS (
        SELECT 1 FROM bim_models
        WHERE name = 'Tenant One Structure Model'
          AND status = 'published' AND version = 2
    ) THEN
        RAISE EXCEPTION 'project manager should be allowed to publish a BIM model';
    END IF;
END;
$$;
INSERT INTO tasks (
    organization_id, project_id, title, due_date, created_by, assigned_user_id
)
VALUES (
    '10000000-0000-4000-8000-000000000001',
    '30000000-0000-4000-8000-000000000001',
    'Project manager task', '2027-02-03',
    '20000000-0000-4000-8000-000000000001',
    '20000000-0000-4000-8000-000000000003'
);
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM tasks WHERE title = 'Project manager task'
          AND assigned_user_id = '20000000-0000-4000-8000-000000000003'
    ) THEN
        RAISE EXCEPTION 'assigned project manager should be allowed to create tasks';
    END IF;
END;
$$;
DO $$
BEGIN
    BEGIN
        INSERT INTO tasks (
            organization_id, project_id, title, due_date, created_by,
            assigned_user_id
        )
        VALUES (
            '10000000-0000-4000-8000-000000000001',
            '30000000-0000-4000-8000-000000000001',
            'Viewer cannot receive task', '2027-02-04',
            '20000000-0000-4000-8000-000000000001',
            '20000000-0000-4000-8000-000000000004'
        );
        RAISE EXCEPTION 'task was unexpectedly assigned to a project viewer';
    EXCEPTION
        WHEN insufficient_privilege THEN NULL;
    END;
END;
$$;
UPDATE tasks
SET title = 'Project manager updated task',
    status = 'in_progress',
    progress = 0.5,
    version = version + 1,
    updated_at = now()
WHERE title = 'Project manager task';
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM tasks
        WHERE title = 'Project manager updated task'
          AND status = 'in_progress'
          AND progress = 0.5
          AND version = 2
    ) THEN
        RAISE EXCEPTION 'assigned project manager should be allowed to update tasks';
    END IF;
END;
$$;
ROLLBACK;

BEGIN;
SET LOCAL ROLE structflow_runtime;
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM projects) THEN
        RAISE EXCEPTION 'projects must be hidden without tenant context';
    END IF;
    IF EXISTS (SELECT 1 FROM tasks) THEN
        RAISE EXCEPTION 'tasks must be hidden without tenant context';
    END IF;
    BEGIN
        INSERT INTO audit_events (
            organization_id, actor_user_id, action, entity_type, entity_id
        )
        VALUES (
            '10000000-0000-4000-8000-000000000001',
            '20000000-0000-4000-8000-000000000001',
            'test.created', 'test', 'missing-context'
        );
        RAISE EXCEPTION 'runtime role unexpectedly wrote without tenant context';
    EXCEPTION
        WHEN insufficient_privilege THEN NULL;
    END;
END;
$$;
COMMIT;

UPDATE memberships
SET role = 'admin'
WHERE organization_id = '10000000-0000-4000-8000-000000000001'
  AND user_id = '20000000-0000-4000-8000-000000000001';

BEGIN;
SET LOCAL ROLE structflow_runtime;
SELECT set_config('app.organization_id', '10000000-0000-4000-8000-000000000001', true);
SELECT set_config('app.user_id', '20000000-0000-4000-8000-000000000001', true);
DO $$
DECLARE
    updated_rows integer;
BEGIN
    UPDATE projects
    SET name = 'Admin update permitted', version = version + 1
    WHERE code = 'ONE';
    GET DIAGNOSTICS updated_rows = ROW_COUNT;
    IF updated_rows <> 1 THEN
        RAISE EXCEPTION 'organization admin should be allowed to update project metadata';
    END IF;
END;
$$;
COMMIT;

UPDATE memberships
SET status = 'suspended'
WHERE organization_id = '10000000-0000-4000-8000-000000000001'
  AND user_id = '20000000-0000-4000-8000-000000000001';

BEGIN;
SET LOCAL ROLE structflow_runtime;
SELECT set_config('app.organization_id', '10000000-0000-4000-8000-000000000001', true);
SELECT set_config('app.user_id', '20000000-0000-4000-8000-000000000001', true);
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM projects) THEN
        RAISE EXCEPTION 'suspended organization member must not see projects';
    END IF;
    IF EXISTS (SELECT 1 FROM tasks) THEN
        RAISE EXCEPTION 'suspended organization member must not see tasks';
    END IF;
    BEGIN
        INSERT INTO audit_events (
            organization_id, actor_user_id, action, entity_type, entity_id
        )
        VALUES (
            '10000000-0000-4000-8000-000000000001',
            '20000000-0000-4000-8000-000000000001',
            'test.created', 'test', 'suspended-member'
        );
        RAISE EXCEPTION 'suspended member unexpectedly wrote an audit event';
    EXCEPTION
        WHEN insufficient_privilege THEN NULL;
    END;
END;
$$;
COMMIT;

UPDATE organizations
SET status = 'suspended'
WHERE id = '10000000-0000-4000-8000-000000000002';

BEGIN;
SET LOCAL ROLE structflow_runtime;
SELECT set_config('app.organization_id', '10000000-0000-4000-8000-000000000002', true);
SELECT set_config('app.user_id', '20000000-0000-4000-8000-000000000002', true);
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM projects) THEN
        RAISE EXCEPTION 'suspended organization member must not see projects';
    END IF;
    IF EXISTS (SELECT 1 FROM tasks) THEN
        RAISE EXCEPTION 'suspended organization member must not see tasks';
    END IF;
    BEGIN
        INSERT INTO audit_events (
            organization_id, actor_user_id, action, entity_type, entity_id
        )
        VALUES (
            '10000000-0000-4000-8000-000000000002',
            '20000000-0000-4000-8000-000000000002',
            'test.created', 'test', 'suspended-organization'
        );
        RAISE EXCEPTION 'suspended organization unexpectedly wrote an audit event';
    EXCEPTION
        WHEN insufficient_privilege THEN NULL;
    END;
END;
$$;
COMMIT;
