GRANT UPDATE (
    name,
    status,
    location,
    client_name,
    project_type,
    budget_amount,
    budget_currency,
    planned_start_date,
    planned_end_date,
    version,
    updated_at
) ON projects TO structflow_runtime;

CREATE POLICY projects_update_owner_admin
    ON projects
    AS RESTRICTIVE
    FOR UPDATE
    TO structflow_runtime
    USING (
        EXISTS (
            SELECT 1
            FROM memberships m
            WHERE m.organization_id = projects.organization_id
              AND m.user_id =
                  NULLIF(current_setting('app.user_id', true), '')::uuid
              AND m.role IN ('owner', 'admin')
              AND m.status = 'active'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1
            FROM memberships m
            WHERE m.organization_id = projects.organization_id
              AND m.user_id =
                  NULLIF(current_setting('app.user_id', true), '')::uuid
              AND m.role IN ('owner', 'admin')
              AND m.status = 'active'
        )
    );
