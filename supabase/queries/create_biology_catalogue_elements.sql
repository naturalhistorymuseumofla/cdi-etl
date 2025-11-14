create table biology_catalogue_elements (
    created_at timestamptz default now(),
    updated_at timestamptz default now(),
    catalogue_irn bigint references biology_catalogue(irn),
    element_id bigint references biology_elements(id),
    primary key (catalogue_irn, element_id)
);