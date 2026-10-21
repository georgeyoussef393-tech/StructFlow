CREATE TABLE project_manager_scopes (
    organization_id uuid NOT NULL,
    project_id uuid NOT NULL,
    manager_user_id uuid NOT NULL,
    PRIMARY KEY (organization_id, project_id, manager_user_id),
    FOREIGN KEY (organization_id, project_id, manager_user_id)
        REFERENCES project_memberships (organization_id, project_id, user_id)
        ON DELETE CASCADE
);

INSERT INTO project_manager_scopes (
    organization_id, project_id, manager_user_id
)
SELECT organization_id, project_id, user_id
FROM project_memberships
WHERE role = 'project_manager'
  AND status = 'active';

CREATE FUNCTION sync_project_manager_scope()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    IF TG_OP IN ('UPDATE', 'DELETE')
       AND OLD.role = 'project_manager' THEN
        DELETE FROM public.project_manager_scopes
        WHERE organization_id = OLD.organization_id
          AND project_id = OLD.project_id
          AND manager_user_id = OLD.user_id;
    END IF;

    IF TG_OP IN ('INSERT', 'UPDATE')
       AND NEW.role = 'project_manager'
       AND NEW.status = 'active' THEN
        INSERT INTO public.project_manager_scopes (
            organization_id, project_id, manager_user_id
        )
        VALUES (NEW.organization_id, NEW.project_id, NEW.user_id)
        ON CONFLICT DO NOTHING;
    END IF;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION sync_project_manager_scope() FROM PUBLIC;

CREATE TRIGGER project_manager_scope_sync
    AFTER INSERT OR UPDATE OF role, status OR DELETE
    ON project_memberships
    FOR EACH ROW
    EXECUTE FUNCTION sync_project_manager_scope();

CREATE FUNCTION app_is_active_project_manager(
    target_organization_id uuid,
    target_project_id uuid
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
    SELECT target_organization_id =
               NULLIF(current_setting('app.organization_id', true), '')::uuid
       AND EXISTS (
           SELECT 1
           FROM public.project_manager_scopes s
           WHERE s.organization_id = target_organization_id
             AND s.project_id = target_project_id
             AND s.manager_user_id =
                 NULLIF(current_setting('app.user_id', true), '')::uuid
       )
       AND public.app_is_active_member(
           target_organization_id,
           NULLIF(current_setting('app.user_id', true), '')::uuid
       );
$$;

REVOKE ALL ON FUNCTION app_is_active_project_manager(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app_is_active_project_manager(uuid, uuid)
    TO structflow_runtime;

ALTER POLICY project_memberships_tenant_isolation
    ON project_memberships
    USING (
        organization_id =
            NULLIF(current_setting('app.organization_id', true), '')::uuid
        AND app_is_active_member(
            organization_id,
            NULLIF(current_setting('app.user_id', true), '')::uuid
        )
        AND (
            user_id = NULLIF(current_setting('app.user_id', true), '')::uuid
            OR EXISTS (
                SELECT 1
                FROM public.memberships m
                WHERE m.organization_id = project_memberships.organization_id
                  AND m.user_id =
                      NULLIF(current_setting('app.user_id', true), '')::uuid
                  AND m.role IN ('owner', 'admin')
                  AND m.status = 'active'
            )
            OR app_is_active_project_manager(
                organization_id,
                project_id
            )
        )
    );

ALTER POLICY tasks_project_manager_create
    ON tasks
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
        AND (
            assigned_user_id IS NULL
            OR EXISTS (
                SELECT 1
                FROM project_memberships pm
                JOIN memberships m
                  ON m.organization_id = pm.organization_id
                 AND m.user_id = pm.user_id
                JOIN users u ON u.id = pm.user_id
                WHERE pm.organization_id = tasks.organization_id
                  AND pm.project_id = tasks.project_id
                  AND pm.user_id = tasks.assigned_user_id
                  AND pm.role IN ('project_manager', 'contributor')
                  AND pm.status = 'active'
                  AND m.status = 'active'
                  AND u.status = 'active'
            )
        )
    );

ALTER POLICY tasks_project_manager_update
    ON tasks
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
        AND (
            assigned_user_id IS NULL
            OR EXISTS (
                SELECT 1
                FROM project_memberships pm
                JOIN memberships m
                  ON m.organization_id = pm.organization_id
                 AND m.user_id = pm.user_id
                JOIN users u ON u.id = pm.user_id
                WHERE pm.organization_id = tasks.organization_id
                  AND pm.project_id = tasks.project_id
                  AND pm.user_id = tasks.assigned_user_id
                  AND pm.role IN ('project_manager', 'contributor')
                  AND pm.status = 'active'
                  AND m.status = 'active'
                  AND u.status = 'active'
            )
        )
    );

GRANT INSERT (assigned_user_id) ON tasks TO structflow_runtime;
GRANT UPDATE (assigned_user_id) ON tasks TO structflow_runtime;
