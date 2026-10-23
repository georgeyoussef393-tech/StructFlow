CREATE TABLE bim_issue_comments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id uuid NOT NULL,
    project_id uuid NOT NULL,
    issue_id uuid NOT NULL,
    body text NOT NULL CHECK (length(trim(body)) BETWEEN 1 AND 5000),
    created_by uuid NOT NULL REFERENCES users(id),
    created_at timestamptz NOT NULL DEFAULT now(),
    FOREIGN KEY (organization_id, project_id, issue_id)
        REFERENCES bim_issues (organization_id, project_id, id)
        ON DELETE CASCADE
);

CREATE INDEX bim_issue_comments_issue_created_idx
    ON bim_issue_comments (organization_id, issue_id, created_at, id);

ALTER TABLE bim_issue_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE bim_issue_comments FORCE ROW LEVEL SECURITY;

CREATE POLICY bim_issue_comments_project_read
    ON bim_issue_comments
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
                WHERE m.organization_id = bim_issue_comments.organization_id
                  AND m.user_id =
                      NULLIF(current_setting('app.user_id', true), '')::uuid
                  AND m.role IN ('owner', 'admin')
                  AND m.status = 'active'
            )
            OR EXISTS (
                SELECT 1
                FROM project_memberships pm
                WHERE pm.organization_id = bim_issue_comments.organization_id
                  AND pm.project_id = bim_issue_comments.project_id
                  AND pm.user_id =
                      NULLIF(current_setting('app.user_id', true), '')::uuid
                  AND pm.status = 'active'
            )
        )
    );

CREATE POLICY bim_issue_comments_project_create
    ON bim_issue_comments
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
                WHERE m.organization_id = bim_issue_comments.organization_id
                  AND m.user_id =
                      NULLIF(current_setting('app.user_id', true), '')::uuid
                  AND m.role IN ('owner', 'admin')
                  AND m.status = 'active'
            )
            OR EXISTS (
                SELECT 1
                FROM project_memberships pm
                WHERE pm.organization_id = bim_issue_comments.organization_id
                  AND pm.project_id = bim_issue_comments.project_id
                  AND pm.user_id =
                      NULLIF(current_setting('app.user_id', true), '')::uuid
                  AND pm.role IN ('project_manager', 'contributor')
                  AND pm.status = 'active'
            )
        )
    );

GRANT SELECT ON bim_issue_comments TO structflow_runtime;
GRANT INSERT (
    organization_id,
    project_id,
    issue_id,
    body,
    created_by
) ON bim_issue_comments TO structflow_runtime;
