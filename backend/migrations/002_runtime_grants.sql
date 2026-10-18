GRANT USAGE ON SCHEMA public TO structflow_runtime;
GRANT SELECT, INSERT ON organizations, users, memberships TO structflow_runtime;
GRANT SELECT, INSERT, UPDATE ON sessions TO structflow_runtime;
GRANT SELECT, INSERT ON projects TO structflow_runtime;
GRANT SELECT ON project_memberships TO structflow_runtime;
GRANT INSERT ON audit_events TO structflow_runtime;
GRANT USAGE, SELECT ON SEQUENCE audit_events_id_seq TO structflow_runtime;
