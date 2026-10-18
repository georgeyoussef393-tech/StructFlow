CREATE POLICY tasks_project_manager_create
    ON tasks
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
                WHERE m.organization_id = tasks.organization_id
                  AND m.user_id =
                      NULLIF(current_setting('app.user_id', true), '')::uuid
                  AND m.role IN ('owner', 'admin')
                  AND m.status = 'active'
            )
            OR EXISTS (
                SELECT 1
                FROM project_memberships pm
                WHERE pm.organization_id = tasks.organization_id
                  AND pm.project_id = tasks.project_id
                  AND pm.user_id =
                      NULLIF(current_setting('app.user_id', true), '')::uuid
                  AND pm.role = 'project_manager'
                  AND pm.status = 'active'
            )
        )
    );

GRANT INSERT (
    organization_id,
    project_id,
    title,
    description,
    status,
    priority,
    due_date,
    progress,
    created_by
) ON tasks TO structflow_runtime;
