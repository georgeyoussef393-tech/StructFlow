ALTER TABLE bim_issue_comments
    ADD COLUMN source_guid uuid,
    ADD COLUMN source_author text CHECK (
        source_author IS NULL OR length(trim(source_author)) BETWEEN 1 AND 200
    );

CREATE UNIQUE INDEX bim_issue_comments_source_guid_unique
    ON bim_issue_comments (organization_id, issue_id, source_guid)
    WHERE source_guid IS NOT NULL;

GRANT INSERT (
    created_at,
    source_guid,
    source_author
) ON bim_issue_comments TO structflow_runtime;
