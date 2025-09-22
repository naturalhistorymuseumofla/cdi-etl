create table anthropology_catalogue (
  id bigserial primary key,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
   -- Metadata
  irn bigint unique not null,
  date_emu_record_modified date,
  date_emu_record_inserted date,
  emu_guid uuid,
  catalogue_number text,
  creator text,
  date_collected text,
  date_received text,

  -- Descriptive fields
  description text,
  object_name text,
  material_type_verbatim text[],   -- array of strings
  date_created text,
  provenience_verbatim text,
  department text,
  section text,

  -- References (nested objects)
  collectors jsonb[],
  donors jsonb[],
  sites jsonb[],

  -- Measurements
  diameter numeric,
  height numeric,
  length numeric,
  width numeric,
  measurement_notes text,

  -- Commentary
  commentary text,

  -- Cultural data
  cultural_attribution_verbatim text[],
  site_summary text,
  site_number text,
  site_name text[],
  site_irn bigint,
  material_type jsonb  -- structured type/subtype pairs
);


alter table anthropology_cultures enable row level security;

-- Create trigger to automatically update the updated_at column
create trigger handle_updated_at
  before update on anthropology_catalogue
  for each row
  execute procedure moddatetime (updated_at);
