CREATE TABLE history_catalogue (
    id SERIAL PRIMARY KEY,           -- Auto-incrementing unique identifier
    created_at timestamptz default now(),
    updated_at timestamptz default now(),
    -- EMu fields
    date_emu_record_modified DATE,   -- Date the EMu record was last modified
    date_emu_record_inserted DATE,   -- Date the EMu record was inserted
    irn BIGINT NOT NULL UNIQUE,      -- Internal Record Number (unique identifier for the record)
    emu_guid UUID NOT NULL,          -- EMu GUID (unique identifier for the record)
    catalogue_number TEXT,           -- Catalogue number
    department TEXT,                 -- Department name
    section TEXT,                    -- Section name
    collection_name TEXT,            -- Collection name
    form TEXT,                       -- Form of the item
    description TEXT,                -- Description of the item
    level_of_description TEXT,       -- Level of description
    title TEXT,                      -- Title of the item
    date_created TEXT,               -- Date the item was created
    subjects JSONB,                  -- Subjects stored as JSON
    creators JSONB                   -- Creators stored as JSON
);

alter table history_catalogue enable row level security;

-- Create trigger to automatically update the updated_at column
create trigger handle_updated_at
  before update on history_catalogue
  for each row
  execute procedure moddatetime (updated_at);