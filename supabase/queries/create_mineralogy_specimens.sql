create table mineralogy_specimens (
  id serial primary key,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),

  -- EMu fields
  specimen_id uuid unique not null,
  catalogue_irn bigint references mineralogy_catalogue(irn),
  taxonomy_irn bigint references mineralogy_taxonomy(irn),
  is_primary_specimen boolean,
  is_display_quality boolean,
  verbatim_colors text,
  colors text[],
  habit text,
  variety text
);


alter table mineralogy_specimens enable row level security;

-- Create trigger to automatically update the updated_at column
create trigger handle_updated_at
  before update on mineralogy_specimens
  for each row
  execute procedure moddatetime (updated_at);
