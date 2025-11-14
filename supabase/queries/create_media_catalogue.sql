create table media_catalogue (
    id bigserial primary key,
    created_at timestamptz default now(),
    updated_at timestamptz default now(),

   -- Metadata
    media_id bigint references media(id),
    irn bigint unique not null,
    domain text
);

alter table media_catalogue enable row level security;

-- Create trigger to automatically update the updated_at column
create trigger handle_updated_at
    before update on media_catalogue
    for each row
    execute procedure moddatetime (updated_at);
