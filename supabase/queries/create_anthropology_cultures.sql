create table anthropology_cultures (
  id bigserial primary key,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
   -- Metadata
  name text not null,                     -- e.g. "Plains Cree"
  type text,                              -- e.g. "people", "region"
  region text,                            -- region name or code
  parent_id bigint,                       -- links back to another culture
  age_start int,                          -- start year/period
  age_end int,                            -- end year/period
  synonyms text[],                        -- array of synonyms
  endonyms text[],                        -- array of endonyms
  aat_id text,                            -- AAT identifier
  wikidata_id text,                       -- Wikidata identifier
  aat_notes text,                         -- notes about the AAT term
  description text,                       -- description of the culture
  airtable_id text unique,                 -- Airtable record ID
  date_airtable_record_modified date     -- date of last modification in Airtable
);


alter table anthropology_cultures enable row level security;

-- Create trigger to automatically update the updated_at column
create trigger handle_updated_at
  before update on anthropology_cultures
  for each row
  execute procedure moddatetime (updated_at);
