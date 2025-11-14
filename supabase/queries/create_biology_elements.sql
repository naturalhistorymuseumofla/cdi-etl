create table biology_elements (
  id bigserial primary key,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),

   -- Metadata
  name text not null,                     -- e.g. "Shoulder"
  parent_id bigint,                       -- links back to another element
  domains text[],                         -- type(s) of biological domain (e.g. "vertebrate", "plant")
  synonyms text[],                        -- array of synonyms
  uberon_id text,                         -- Uberon identifier
  description text                       -- description of the culture
);


alter table biology_elements enable row level security;

-- Create trigger to automatically update the updated_at column
create trigger handle_updated_at
  before update on biology_elements
  for each row
  execute procedure moddatetime (updated_at);
