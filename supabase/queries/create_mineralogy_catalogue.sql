create table mineralogy_catalogue (
  id serial primary key,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  
   -- Metadata
  irn bigint unique not null,
  date_emu_record_modified date,
  date_emu_record_inserted date,
  catalogue_number text,

  -- EMu fields
  emu_guid uuid,
  category text,
  size text,
  verbatim_size text,
  jewelry_type text,
  description text,
  dimensions text,
  length float,
  width float,
  height float,
);


alter table mineralogy_catalogue enable row level security;

-- Create trigger to automatically update the updated_at column
create trigger handle_updated_at
  before update on mineralogy_catalogue
  for each row
  execute procedure moddatetime (updated_at);
