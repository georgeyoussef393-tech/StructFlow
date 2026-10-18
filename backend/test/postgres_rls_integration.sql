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
END;
$$;

INSERT INTO organizations (id, name, slug)
VALUES
    ('10000000-0000-4000-8000-000000000001', 'Tenant One', 'tenant-one-test'),
    ('10000000-0000-4000-8000-000000000002', 'Tenant Two', 'tenant-two-test');

INSERT INTO users (id, full_name, email, password_hash)
VALUES
    ('20000000-0000-4000-8000-000000000001', 'Tenant One User', 'one@test.invalid', 'test-hash'),
    ('20000000-0000-4000-8000-000000000002', 'Tenant Two User', 'two@test.invalid', 'test-hash');

INSERT INTO memberships (organization_id, user_id, role)
VALUES
    ('10000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', 'member'),
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
VALUES ('10000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', 'contributor');

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
COMMIT;

BEGIN;
SET LOCAL ROLE structflow_runtime;
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM projects) THEN
        RAISE EXCEPTION 'projects must be hidden without tenant context';
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
