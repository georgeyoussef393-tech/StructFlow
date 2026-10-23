CREATE TABLE bim_models (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id uuid NOT NULL,
    project_id uuid NOT NULL,
    name text NOT NULL CHECK (length(trim(name)) BETWEEN 2 AND 200),
    discipline text NOT NULL
        CHECK (length(trim(discipline)) BETWEEN 1 AND 120),
    revision text NOT NULL CHECK (length(trim(revision)) BETWEEN 1 AND 80),
    status text NOT NULL DEFAULT 'in_review' CHECK (
        status IN ('in_review', 'published', 'archived')
    ),
    created_by uuid NOT NULL REFERENCES users(id),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    FOREIGN KEY (organization_id, project_id)
        REFERENCES projects (organization_id, id) ON DELETE CASCADE,
    UNIQUE (organization_id, project_id, id)
);

CREATE INDEX bim_models_project_updated_idx
    ON bim_models (organization_id, project_id, updated_at DESC);

ALTER TABLE bim_models ENABLE ROW LEVEL SECURITY;
ALTER TABLE bim_models FORCE ROW LEVEL SECURITY;

CREATE POLICY bim_models_project_read
    ON bim_models
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
                WHERE m.organization_id = bim_models.organization_id
                  AND m.user_id =
                      NULLIF(current_setting('app.user_id', true), '')::uuid
                  AND m.role IN ('owner', 'admin')
                  AND m.status = 'active'
            )
            OR EXISTS (
                SELECT 1
                FROM project_memberships pm
                WHERE pm.organization_id = bim_models.organization_id
                  AND pm.project_id = bim_models.project_id
                  AND pm.user_id =
                      NULLIF(current_setting('app.user_id', true), '')::uuid
                  AND pm.status = 'active'
            )
        )
    );

CREATE POLICY bim_models_project_create
    ON bim_models
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
                WHERE m.organization_id = bim_models.organization_id
                  AND m.user_id =
                      NULLIF(current_setting('app.user_id', true), '')::uuid
                  AND m.role IN ('owner', 'admin')
                  AND m.status = 'active'
            )
            OR EXISTS (
                SELECT 1
                FROM project_memberships pm
                WHERE pm.organization_id = bim_models.organization_id
                  AND pm.project_id = bim_models.project_id
                  AND pm.user_id =
                      NULLIF(current_setting('app.user_id', true), '')::uuid
                  AND pm.role IN ('project_manager', 'contributor')
                  AND pm.status = 'active'
            )
        )
    );

GRANT SELECT ON bim_models TO structflow_runtime;
GRANT INSERT (
    organization_id,
    project_id,
    name,
    discipline,
    revision,
    created_by
) ON bim_models TO structflow_runtime;
