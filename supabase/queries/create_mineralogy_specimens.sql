create table mineralogy_taxonomy (
  id serial primary key,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  
   -- Metadata
  irn bigint unique not null,
  date_emu_record_modified date,
  date_emu_record_inserted date,

  -- EMu fields

);


alter table anthropology_cultures enable row level security;

-- Create trigger to automatically update the updated_at column
create trigger handle_updated_at
  before update on mineralogy_taxonomy
  for each row
  execute procedure moddatetime (updated_at);
