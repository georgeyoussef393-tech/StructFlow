CREATE TABLE tasks (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id uuid NOT NULL,
    project_id uuid NOT NULL,
    title text NOT NULL CHECK (length(trim(title)) BETWEEN 2 AND 200),
    description text NOT NULL DEFAULT '' CHECK (length(description) <= 10000),
    status text NOT NULL DEFAULT 'todo'
        CHECK (status IN ('todo', 'in_progress', 'review', 'done')),
    priority text NOT NULL DEFAULT 'medium'
        CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    assigned_user_id uuid,
    due_date date NOT NULL,
    progress numeric(5, 4) NOT NULL DEFAULT 0
        CHECK (progress BETWEEN 0 AND 1),
    created_by uuid NOT NULL REFERENCES users(id),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    version integer NOT NULL DEFAULT 1 CHECK (version > 0),
    UNIQUE (organization_id, id),
    FOREIGN KEY (organization_id, project_id)
        REFERENCES projects (organization_id, id) ON DELETE CASCADE,
    FOREIGN KEY (organization_id, assigned_user_id)
        REFERENCES memberships (organization_id, user_id)
);

CREATE INDEX tasks_project_updated_idx
    ON tasks (organization_id, project_id, updated_at DESC);
CREATE INDEX tasks_assignee_due_idx
    ON tasks (organization_id, assigned_user_id, due_date)
    WHERE assigned_user_id IS NOT NULL;

ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks FORCE ROW LEVEL SECURITY;
CREATE POLICY tasks_project_access
    ON tasks
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
                  AND pm.status = 'active'
            )
        )
    );

GRANT SELECT ON tasks TO structflow_runtime;
