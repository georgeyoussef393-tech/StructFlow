CREATE TABLE bim_issues (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id uuid NOT NULL,
    project_id uuid NOT NULL,
    bcf_guid uuid,
    title text NOT NULL CHECK (length(trim(title)) BETWEEN 2 AND 200),
    description text NOT NULL DEFAULT ''
        CHECK (length(description) <= 10000),
    discipline text NOT NULL CHECK (length(trim(discipline)) BETWEEN 1 AND 200),
    location text NOT NULL CHECK (length(trim(location)) BETWEEN 1 AND 300),
    severity text NOT NULL CHECK (
        severity IN ('low', 'medium', 'high', 'critical')
    ),
    status text NOT NULL DEFAULT 'open' CHECK (
        status IN ('open', 'in_progress', 'resolved')
    ),
    assigned_to text NOT NULL DEFAULT ''
        CHECK (length(assigned_to) <= 160),
    due_date date NOT NULL,
    created_by uuid NOT NULL REFERENCES users(id),
    version integer NOT NULL DEFAULT 1 CHECK (version >= 1),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    FOREIGN KEY (organization_id, project_id)
        REFERENCES projects (organization_id, id) ON DELETE CASCADE,
    UNIQUE (organization_id, project_id, id)
);

CREATE UNIQUE INDEX bim_issues_project_bcf_guid_unique
    ON bim_issues (organization_id, project_id, bcf_guid)
    WHERE bcf_guid IS NOT NULL;

CREATE INDEX bim_issues_project_status_due_idx
    ON bim_issues (organization_id, project_id, status, due_date);

ALTER TABLE bim_issues ENABLE ROW LEVEL SECURITY;
ALTER TABLE bim_issues FORCE ROW LEVEL SECURITY;

CREATE POLICY bim_issues_project_read
    ON bim_issues
    FOR SELECT
    USING (
        organization_id =
            NULLIF(current_setting('app.organization_id', true), '')::uuid
        AND app_is_active_member(
            organization_id,
            NULLIF(current_setting('app.user_id', true), '')::uuid
        )
        AND (
            EXISTS (
                SELECT 1
                FROM memberships m
                WHERE m.organization_id = bim_issues.organization_id
                  AND m.user_id =
                      NULLIF(current_setting('app.user_id', true), '')::uuid
                  AND m.role IN ('owner', 'admin')
                  AND m.status = 'active'
            )
            OR EXISTS (
                SELECT 1
                FROM project_memberships pm
                WHERE pm.organization_id = bim_issues.organization_id
                  AND pm.project_id = bim_issues.project_id
                  AND pm.user_id =
                      NULLIF(current_setting('app.user_id', true), '')::uuid
                  AND pm.status = 'active'
            )
        )
    );

CREATE POLICY bim_issues_project_create
    ON bim_issues
    FOR INSERT
    WITH CHECK (
        organization_id =
            NULLIF(current_setting('app.organization_id', true), '')::uuid
        AND app_is_active_member(
            organization_id,
            NULLIF(current_setting('app.user_id', true), '')::uuid
        )
        AND created_by =
            NULLIF(current_setting('app.user_id', true), '')::uuid
        AND (
            EXISTS (
                SELECT 1
                FROM memberships m
                WHERE m.organization_id = bim_issues.organization_id
                  AND m.user_id =
                      NULLIF(current_setting('app.user_id', true), '')::uuid
                  AND m.role IN ('owner', 'admin')
                  AND m.status = 'active'
            )
            OR EXISTS (
                SELECT 1
                FROM project_memberships pm
                WHERE pm.organization_id = bim_issues.organization_id
                  AND pm.project_id = bim_issues.project_id
                  AND pm.user_id =
                      NULLIF(current_setting('app.user_id', true), '')::uuid
                  AND pm.role IN ('project_manager', 'contributor')
                  AND pm.status = 'active'
            )
        )
    );

CREATE POLICY bim_issues_project_update
    ON bim_issues
    FOR UPDATE
    USING (
        organization_id =
            NULLIF(current_setting('app.organization_id', true), '')::uuid
        AND app_is_active_member(
            organization_id,
            NULLIF(current_setting('app.user_id', true), '')::uuid
        )
        AND (
            EXISTS (
                SELECT 1
                FROM memberships m
                WHERE m.organization_id = bim_issues.organization_id
                  AND m.user_id =
                      NULLIF(current_setting('app.user_id', true), '')::uuid
                  AND m.role IN ('owner', 'admin')
                  AND m.status = 'active'
            )
            OR EXISTS (
                SELECT 1
                FROM project_memberships pm
                WHERE pm.organization_id = bim_issues.organization_id
                  AND pm.project_id = bim_issues.project_id
                  AND pm.user_id =
                      NULLIF(current_setting('app.user_id', true), '')::uuid
                  AND pm.role = 'project_manager'
                  AND pm.status = 'active'
            )
        )
    )
    WITH CHECK (
        organization_id =
            NULLIF(current_setting('app.organization_id', true), '')::uuid
        AND app_is_active_member(
            organization_id,
            NULLIF(current_setting('app.user_id', true), '')::uuid
        )
        AND (
            EXISTS (
                SELECT 1
                FROM memberships m
                WHERE m.organization_id = bim_issues.organization_id
                  AND m.user_id =
                      NULLIF(current_setting('app.user_id', true), '')::uuid
                  AND m.role IN ('owner', 'admin')
                  AND m.status = 'active'
            )
            OR EXISTS (
                SELECT 1
                FROM project_memberships pm
                WHERE pm.organization_id = bim_issues.organization_id
                  AND pm.project_id = bim_issues.project_id
                  AND pm.user_id =
                      NULLIF(current_setting('app.user_id', true), '')::uuid
                  AND pm.role = 'project_manager'
                  AND pm.status = 'active'
            )
        )
    );

GRANT SELECT ON bim_issues TO structflow_runtime;
GRANT INSERT (
    organization_id,
    project_id,
    bcf_guid,
    title,
    description,
    discipline,
    location,
    severity,
    status,
    assigned_to,
    due_date,
    created_by
) ON bim_issues TO structflow_runtime;
GRANT UPDATE (status, version, updated_at)
    ON bim_issues TO structflow_runtime;
