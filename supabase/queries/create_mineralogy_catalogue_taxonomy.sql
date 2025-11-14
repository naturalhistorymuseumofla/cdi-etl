create table mineralogy_catalogue_taxonomy (
    created_at timestamptz default now(),
    updated_at timestamptz default now(),
    catalogue_irn bigint references mineralogy_catalogue(irn),
    taxonomy_id bigint references mineralogy_taxonomy(id),
    primary key (catalogue_irn, taxonomy_id)
);