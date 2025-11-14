create table biology_catalogue (
    id bigserial primary key,
    created_at timestamptz default now(),
    updated_at timestamptz default now(),

   -- Metadata
    irn bigint unique not null,
    date_emu_record_modified date,
    date_emu_record_inserted date,
    emu_guid uuid,
    catalogue_number text,

  -- Descriptive fields
    department text,
    caste text,
    sex text,
    life_stage text,
    side text,
    type_status text,
    verbatim_element text,
    locality_irn bigint,
    locality text, 
    taxon_irn bigint,

    -- Foreign key to biology_taxonomy(irn)
    CONSTRAINT fk_biology_catalogue_taxon_irn
      FOREIGN KEY (taxon_irn) REFERENCES biology_taxonomy (irn)
      ON DELETE SET NULL
      ON UPDATE CASCADE
);

alter table biology_catalogue enable row level security;

-- Create trigger to automatically update the updated_at column
create trigger handle_updated_at
  before update on biology_catalogue
  for each row
  execute procedure moddatetime (updated_at);