create table anthropology_catalogue_cultures_join (
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  catalogue_irn bigint references anthropology_catalogue(irn),
  cultures_id bigint references anthropology_cultures(id),
  primary key (catalogue_irn, cultures_id)
);

alter table anthropology_catalogue_cultures_join enable row level security;

-- Create trigger to automatically update the updated_at column
create trigger handle_updated_at
  before update on anthropology_catalogue_cultures_join
  for each row
  execute procedure moddatetime (updated_at);