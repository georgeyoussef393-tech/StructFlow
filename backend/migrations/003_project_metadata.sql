ALTER TABLE projects
    ADD COLUMN client_name text NOT NULL DEFAULT ''
        CHECK (length(client_name) <= 160),
    ADD COLUMN project_type text NOT NULL DEFAULT 'Commercial'
        CHECK (
            project_type IN (
                'Commercial',
                'Residential',
                'Industrial',
                'Infrastructure',
                'Hospitality',
                'Healthcare'
            )
        ),
    ADD COLUMN budget_amount numeric(20, 2)
        CHECK (budget_amount IS NULL OR budget_amount >= 0),
    ADD COLUMN budget_currency char(3) NOT NULL DEFAULT 'USD'
        CHECK (budget_currency ~ '^[A-Z]{3}$'),
    ADD COLUMN planned_start_date date,
    ADD COLUMN planned_end_date date,
    ADD COLUMN version integer NOT NULL DEFAULT 1
        CHECK (version > 0),
    ADD CONSTRAINT projects_planned_dates_ordered
        CHECK (
            planned_start_date IS NULL
            OR planned_end_date IS NULL
            OR planned_end_date >= planned_start_date
        );
