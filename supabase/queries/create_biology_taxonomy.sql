create table biology_taxonomy (
    id bigserial primary key,
    created_at timestamptz default now(),
    updated_at timestamptz default now(),

   -- Metadata
    irn bigint unique not null,
    date_emu_record_modified date,
    date_emu_record_inserted date,
    emu_guid uuid,
    current_name_irn bigint,

    -- Descriptive fields
    department text,
    parent_irn bigint,
    scientific_name text,
    taxon_rank text,
    kingdom text,
    phylum text,
    subphylum text,
    superclass text,
    class text,
    subclass text,
    superorder text,
    "order" text,
    suborder text,
    infraorder text,
    superfamily text,
    family text,
    subfamily text,
    tribe text,
    genus text,
    subgenus text,
    species text,
    subspecies text,
    common_name text
);


alter table biology_taxonomy enable row level security;

-- Create trigger to automatically update the updated_at column
create trigger handle_updated_at
  before update on biology_taxonomy
  for each row
  execute procedure moddatetime (updated_at);