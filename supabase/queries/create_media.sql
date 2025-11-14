create table media (
    id bigserial primary key,
    created_at timestamptz default now(),
    updated_at timestamptz default now(),

    -- Metadata
    dams_id bigint unique not null,
    source text,
    format text,
    creator text,
    license text,
    type text,

    -- Media fields
    url text,
    title text,
    description text,
    uploaded_datetime timestamptz,
    publish_to_collection_page boolean default false,
    is_authoritative boolean default false
);

alter table media enable row level security;

-- Create trigger to automatically update the updated_at column
create trigger handle_updated_at
  before update on media
  for each row
  execute procedure moddatetime (updated_at);