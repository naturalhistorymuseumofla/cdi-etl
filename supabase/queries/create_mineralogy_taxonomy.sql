create table mineralogy_taxonomy (
  id serial primary key,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
   -- Metadata
  irn bigint unique not null,
  date_emu_record_modified date,
  date_emu_record_inserted date,

  -- EMu fields
  species text,
  "group" text,
  formula text,
  is_valid boolean,

  -- Mindat fields
  mindat_id integer,
  mindat_name text,
  mindat_group_id integer,  -- references mindat_id
  mindat_ima_status text[],  
  mindat_ima_notes text,
  mindat_elements text[],  
  mindat_formula text,
  mindat_variety_of integer, -- references mindat_id
  mindat_syn_id integer,  -- references mindat_id
  mindat_entry_type text, -- enum: "mineral", "variety", "synonym"
  mindat_description text,
  mindat_tenacity text,
  mindat_strunz_1 integer,
  mindat_strunz_2 text,
  mindat_strunz_3 text,
  mindat_strunz_4 text,
  mindat_rock_parent integer, -- references mindat_id
  mindat_rock_grandparent integer -- references mindat_id
);


alter table mineralogy_taxonomy enable row level security;

-- Create trigger to automatically update the updated_at column
create trigger handle_updated_at
  before update on mineralogy_taxonomy
  for each row
  execute procedure moddatetime (updated_at);
