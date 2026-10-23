ALTER TABLE bim_models
    ADD COLUMN version integer NOT NULL DEFAULT 1 CHECK (version >= 1);

CREATE POLICY bim_models_project_update
    ON bim_models
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
                  AND pm.role = 'project_manager'
                  AND pm.status = 'active'
            )
        )
    );

GRANT UPDATE (status, version, updated_at)
    ON bim_models TO structflow_runtime;
