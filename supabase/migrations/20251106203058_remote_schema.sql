create extension if not exists "moddatetime" with schema "extensions";

drop extension if exists "pg_net";

drop extension if exists "pgjwt";

CREATE SEQUENCE IF NOT EXISTS public.biology_catalogue_id_seq;

CREATE SEQUENCE IF NOT EXISTS public.biology_taxonomy_id_seq;

CREATE SEQUENCE IF NOT EXISTS public.media_catalogue_id_seq;

CREATE SEQUENCE IF NOT EXISTS public.media_id_seq;

CREATE SEQUENCE IF NOT EXISTS public.mineralogy_catalogue_id_seq;

CREATE SEQUENCE IF NOT EXISTS public.mineralogy_taxonomy_id_seq;

drop trigger if exists "handle_updated_at" on "public"."history_catalogue";

drop trigger if exists "tsvector_update" on "public"."organisms";

drop trigger if exists "handle_updated_at" on "public"."anthropology_catalogue";

drop trigger if exists "handle_updated_at" on "public"."anthropology_catalogue_cultures_join";

drop trigger if exists "handle_updated_at" on "public"."anthropology_cultures";

drop policy "Enable read access for all users" on "public"."organisms";

drop policy "Enable read access for all users" on "public"."taxonomy";

revoke delete on table "public"."history_catalogue" from "anon";

revoke insert on table "public"."history_catalogue" from "anon";

revoke references on table "public"."history_catalogue" from "anon";

revoke select on table "public"."history_catalogue" from "anon";

revoke trigger on table "public"."history_catalogue" from "anon";

revoke truncate on table "public"."history_catalogue" from "anon";

revoke update on table "public"."history_catalogue" from "anon";

revoke delete on table "public"."history_catalogue" from "authenticated";

revoke insert on table "public"."history_catalogue" from "authenticated";

revoke references on table "public"."history_catalogue" from "authenticated";

revoke select on table "public"."history_catalogue" from "authenticated";

revoke trigger on table "public"."history_catalogue" from "authenticated";

revoke truncate on table "public"."history_catalogue" from "authenticated";

revoke update on table "public"."history_catalogue" from "authenticated";

revoke delete on table "public"."history_catalogue" from "service_role";

revoke insert on table "public"."history_catalogue" from "service_role";

revoke references on table "public"."history_catalogue" from "service_role";

revoke select on table "public"."history_catalogue" from "service_role";

revoke trigger on table "public"."history_catalogue" from "service_role";

revoke truncate on table "public"."history_catalogue" from "service_role";

revoke update on table "public"."history_catalogue" from "service_role";

revoke delete on table "public"."minerals" from "anon";

revoke insert on table "public"."minerals" from "anon";

revoke references on table "public"."minerals" from "anon";

revoke select on table "public"."minerals" from "anon";

revoke trigger on table "public"."minerals" from "anon";

revoke truncate on table "public"."minerals" from "anon";

revoke update on table "public"."minerals" from "anon";

revoke delete on table "public"."minerals" from "authenticated";

revoke insert on table "public"."minerals" from "authenticated";

revoke references on table "public"."minerals" from "authenticated";

revoke select on table "public"."minerals" from "authenticated";

revoke trigger on table "public"."minerals" from "authenticated";

revoke truncate on table "public"."minerals" from "authenticated";

revoke update on table "public"."minerals" from "authenticated";

revoke delete on table "public"."minerals" from "service_role";

revoke insert on table "public"."minerals" from "service_role";

revoke references on table "public"."minerals" from "service_role";

revoke select on table "public"."minerals" from "service_role";

revoke trigger on table "public"."minerals" from "service_role";

revoke truncate on table "public"."minerals" from "service_role";

revoke update on table "public"."minerals" from "service_role";

revoke delete on table "public"."minerals_catalogue_taxonomy_join" from "anon";

revoke insert on table "public"."minerals_catalogue_taxonomy_join" from "anon";

revoke references on table "public"."minerals_catalogue_taxonomy_join" from "anon";

revoke select on table "public"."minerals_catalogue_taxonomy_join" from "anon";

revoke trigger on table "public"."minerals_catalogue_taxonomy_join" from "anon";

revoke truncate on table "public"."minerals_catalogue_taxonomy_join" from "anon";

revoke update on table "public"."minerals_catalogue_taxonomy_join" from "anon";

revoke delete on table "public"."minerals_catalogue_taxonomy_join" from "authenticated";

revoke insert on table "public"."minerals_catalogue_taxonomy_join" from "authenticated";

revoke references on table "public"."minerals_catalogue_taxonomy_join" from "authenticated";

revoke select on table "public"."minerals_catalogue_taxonomy_join" from "authenticated";

revoke trigger on table "public"."minerals_catalogue_taxonomy_join" from "authenticated";

revoke truncate on table "public"."minerals_catalogue_taxonomy_join" from "authenticated";

revoke update on table "public"."minerals_catalogue_taxonomy_join" from "authenticated";

revoke delete on table "public"."minerals_catalogue_taxonomy_join" from "service_role";

revoke insert on table "public"."minerals_catalogue_taxonomy_join" from "service_role";

revoke references on table "public"."minerals_catalogue_taxonomy_join" from "service_role";

revoke select on table "public"."minerals_catalogue_taxonomy_join" from "service_role";

revoke trigger on table "public"."minerals_catalogue_taxonomy_join" from "service_role";

revoke truncate on table "public"."minerals_catalogue_taxonomy_join" from "service_role";

revoke update on table "public"."minerals_catalogue_taxonomy_join" from "service_role";

revoke delete on table "public"."minerals_taxonomy" from "anon";

revoke insert on table "public"."minerals_taxonomy" from "anon";

revoke references on table "public"."minerals_taxonomy" from "anon";

revoke select on table "public"."minerals_taxonomy" from "anon";

revoke trigger on table "public"."minerals_taxonomy" from "anon";

revoke truncate on table "public"."minerals_taxonomy" from "anon";

revoke update on table "public"."minerals_taxonomy" from "anon";

revoke delete on table "public"."minerals_taxonomy" from "authenticated";

revoke insert on table "public"."minerals_taxonomy" from "authenticated";

revoke references on table "public"."minerals_taxonomy" from "authenticated";

revoke select on table "public"."minerals_taxonomy" from "authenticated";

revoke trigger on table "public"."minerals_taxonomy" from "authenticated";

revoke truncate on table "public"."minerals_taxonomy" from "authenticated";

revoke update on table "public"."minerals_taxonomy" from "authenticated";

revoke delete on table "public"."minerals_taxonomy" from "service_role";

revoke insert on table "public"."minerals_taxonomy" from "service_role";

revoke references on table "public"."minerals_taxonomy" from "service_role";

revoke select on table "public"."minerals_taxonomy" from "service_role";

revoke trigger on table "public"."minerals_taxonomy" from "service_role";

revoke truncate on table "public"."minerals_taxonomy" from "service_role";

revoke update on table "public"."minerals_taxonomy" from "service_role";

revoke delete on table "public"."organisms" from "anon";

revoke insert on table "public"."organisms" from "anon";

revoke references on table "public"."organisms" from "anon";

revoke select on table "public"."organisms" from "anon";

revoke trigger on table "public"."organisms" from "anon";

revoke truncate on table "public"."organisms" from "anon";

revoke update on table "public"."organisms" from "anon";

revoke delete on table "public"."organisms" from "authenticated";

revoke insert on table "public"."organisms" from "authenticated";

revoke references on table "public"."organisms" from "authenticated";

revoke select on table "public"."organisms" from "authenticated";

revoke trigger on table "public"."organisms" from "authenticated";

revoke truncate on table "public"."organisms" from "authenticated";

revoke update on table "public"."organisms" from "authenticated";

revoke delete on table "public"."organisms" from "service_role";

revoke insert on table "public"."organisms" from "service_role";

revoke references on table "public"."organisms" from "service_role";

revoke select on table "public"."organisms" from "service_role";

revoke trigger on table "public"."organisms" from "service_role";

revoke truncate on table "public"."organisms" from "service_role";

revoke update on table "public"."organisms" from "service_role";

revoke delete on table "public"."taxonomy" from "anon";

revoke insert on table "public"."taxonomy" from "anon";

revoke references on table "public"."taxonomy" from "anon";

revoke select on table "public"."taxonomy" from "anon";

revoke trigger on table "public"."taxonomy" from "anon";

revoke truncate on table "public"."taxonomy" from "anon";

revoke update on table "public"."taxonomy" from "anon";

revoke delete on table "public"."taxonomy" from "authenticated";

revoke insert on table "public"."taxonomy" from "authenticated";

revoke references on table "public"."taxonomy" from "authenticated";

revoke select on table "public"."taxonomy" from "authenticated";

revoke trigger on table "public"."taxonomy" from "authenticated";

revoke truncate on table "public"."taxonomy" from "authenticated";

revoke update on table "public"."taxonomy" from "authenticated";

revoke delete on table "public"."taxonomy" from "service_role";

revoke insert on table "public"."taxonomy" from "service_role";

revoke references on table "public"."taxonomy" from "service_role";

revoke select on table "public"."taxonomy" from "service_role";

revoke trigger on table "public"."taxonomy" from "service_role";

revoke truncate on table "public"."taxonomy" from "service_role";

revoke update on table "public"."taxonomy" from "service_role";

alter table "public"."history_catalogue" drop constraint "history_catalogue_irn_key";

-- If media_catalogue has a FK referencing media(id), drop it first so we can remove
-- the media id constraint/index safely. We'll recreate/validate it later in the migration.
ALTER TABLE IF EXISTS public.media_catalogue
  DROP CONSTRAINT IF EXISTS media_catalogue_media_id_fkey;

alter table "public"."media" drop constraint "media_id_key";

-- If minerals_catalogue_taxonomy_join has a FK referencing minerals(irn), drop it
-- first so we can remove the minerals irn constraint/index safely. We'll recreate/validate it later.
ALTER TABLE IF EXISTS public.minerals_catalogue_taxonomy_join
  DROP CONSTRAINT IF EXISTS minerals_catalogue_taxonomy_join_irn_fkey;

alter table "public"."minerals" drop constraint "minerals_irn_key";

-- Make these conditional in case they don't exist in the target DB already.
ALTER TABLE IF EXISTS public.minerals_catalogue_taxonomy_join
  DROP CONSTRAINT IF EXISTS minerals_catalogue_taxonomy_join_irn_fkey;

ALTER TABLE IF EXISTS public.minerals_catalogue_taxonomy_join
  DROP CONSTRAINT IF EXISTS minerals_catalogue_taxonomy_join_taxon_irn_fkey;

alter table "public"."minerals_taxonomy" drop constraint "minerals_taxonomy_irn_key";


alter table "public"."organisms" drop constraint "organisms_taxon_irn_fkey";

-- Make this conditional in case the constraint isn't present in the target DB.
ALTER TABLE IF EXISTS public.media_catalogue
  DROP CONSTRAINT IF EXISTS media_catalogue_media_id_fkey;

drop function if exists "public"."get_department"(irn_value integer);

drop function if exists "public"."get_distinct_values"(column_name text, table_name text);

drop function if exists "public"."search"(search_term text);

drop function if exists "public"."search_organisms"(search_term text);

drop function if exists "public"."search_taxonomy"(search_term text);

alter table "public"."history_catalogue" drop constraint "history_catalogue_pkey";

alter table "public"."minerals" drop constraint "minerals_pkey";

alter table "public"."minerals_catalogue_taxonomy_join" drop constraint "minerals_catalogue_taxonomy_join_pkey";

alter table "public"."minerals_taxonomy" drop constraint "minerals_taxonomy_pkey";

alter table "public"."organisms" drop constraint "organisms_pkey";

alter table "public"."taxonomy" drop constraint "taxonomy_pkey";

drop index if exists "public"."history_catalogue_irn_key";

drop index if exists "public"."history_catalogue_pkey";

drop index if exists "public"."media_id_key";

drop index if exists "public"."minerals_catalogue_taxonomy_join_pkey";

drop index if exists "public"."minerals_irn_key";

drop index if exists "public"."minerals_pkey";

drop index if exists "public"."minerals_taxonomy_irn_key";

drop index if exists "public"."minerals_taxonomy_pkey";

drop index if exists "public"."organisms_pkey";

drop index if exists "public"."search_index";

drop index if exists "public"."taxonomy_pkey";

drop table "public"."history_catalogue";

drop table "public"."minerals";

drop table "public"."minerals_catalogue_taxonomy_join";

drop table "public"."minerals_taxonomy";

drop table "public"."organisms";

drop table "public"."taxonomy";


  create table "public"."biology_catalogue" (
    "id" bigint not null default nextval('public.biology_catalogue_id_seq'::regclass),
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "irn" bigint not null,
    "date_emu_record_modified" date,
    "date_emu_record_inserted" date,
    "emu_guid" uuid,
    "catalogue_number" text,
    "department" text,
    "caste" text,
    "sex" text,
    "life_stage" text,
    "side" text,
    "element" text,
    "type_status" text,
    "locality_irn" bigint,
    "locality" text,
    "taxon_irn" bigint
      );


alter table "public"."biology_catalogue" enable row level security;


  create table "public"."biology_taxonomy" (
    "id" bigint not null default nextval('public.biology_taxonomy_id_seq'::regclass),
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "irn" bigint not null,
    "date_emu_record_modified" date,
    "date_emu_record_inserted" date,
    "emu_guid" uuid,
    "catalogue_number" text,
    "department" text,
    "parent_irn" bigint,
    "scientific_name" text,
    "rank" text,
    "kingdom" text,
    "phylum" text,
    "subphylum" text,
    "superclass" text,
    "class" text,
    "subclass" text,
    "superorder" text,
    "order" text,
    "suborder" text,
    "infraorder" text,
    "superfamily" text,
    "family" text,
    "subfamily" text,
    "tribe" text,
    "genus" text,
    "subgenus" text,
    "species" text,
    "subspecies" text,
    "common_name" text
      );


alter table "public"."biology_taxonomy" enable row level security;


  create table "public"."mineralogy_catalogue" (
    "id" integer not null default nextval('public.mineralogy_catalogue_id_seq'::regclass),
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "irn" bigint not null,
    "date_emu_record_modified" date,
    "date_emu_record_inserted" date,
    "catalogue_number" text,
    "emu_guid" uuid,
    "category" text,
    "size" text,
    "verbatim_size" text,
    "jewelry_type" text,
    "description" text,
    "dimensions" text,
    "length" double precision,
    "width" double precision,
    "height" double precision,
    "specimens" jsonb
      );


alter table "public"."mineralogy_catalogue" enable row level security;


  create table "public"."mineralogy_catalogue_taxonomy" (
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "catalogue_irn" bigint not null,
    "taxonomy_id" bigint not null
      );



  create table "public"."mineralogy_taxonomy" (
    "id" integer not null default nextval('public.mineralogy_taxonomy_id_seq'::regclass),
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "irn" bigint not null,
    "date_emu_record_modified" date,
    "date_emu_record_inserted" date,
    "species" text,
    "group" text,
    "formula" text,
    "is_valid" boolean,
    "mindat_id" integer,
    "mindat_name" text,
    "mindat_group_id" integer,
    "mindat_ima_status" text[],
    "mindat_ima_notes" text,
    "mindat_elements" text[],
    "mindat_formula" text,
    "mindat_variety_of" integer,
    "mindat_syn_id" integer,
    "mindat_entry_type" text,
    "mindat_description" text,
    "mindat_tenacity" text,
    "mindat_strunz_1" integer,
    "mindat_strunz_2" text,
    "mindat_strunz_3" text,
    "mindat_strunz_4" text,
    "mindat_rock_parent" integer,
    "mindat_rock_grandparent" integer
      );


alter table "public"."mineralogy_taxonomy" enable row level security;

alter table "public"."media" drop column "department";

alter table "public"."media" drop column "publish_to_collection_pages";

alter table "public"."media" drop column "uploaded";

alter table "public"."media" add column "publish_to_collection_page" boolean default false;

alter table "public"."media" add column "updated_at" timestamp with time zone default now();

alter table "public"."media" add column "uploaded_datetime" timestamp with time zone;

alter table "public"."media" alter column "created_at" drop not null;

alter table "public"."media" alter column "dams_id" set data type bigint using "dams_id"::bigint;

-- If the column is an identity column, drop the identity first (no-op if not present),
-- then set the sequence default. This avoids errors when the source DB uses IDENTITY.
ALTER TABLE IF EXISTS public.media
  ALTER COLUMN id DROP IDENTITY IF EXISTS;
-- Only set the default if the sequence exists. Some targets may not have the
-- sequence created (or it may be managed differently), so guard the ALTER.
DO $do$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE c.relkind = 'S' AND c.relname = 'media_id_seq' AND n.nspname = 'public'
  ) THEN
    EXECUTE 'ALTER TABLE IF EXISTS public.media ALTER COLUMN id SET DEFAULT nextval(''public.media_id_seq''::regclass)';
  END IF;
END
$do$;

alter table "public"."media" alter column "is_authoritative" set default false;

alter table "public"."media_catalogue" add column "updated_at" timestamp with time zone default now();

alter table "public"."media_catalogue" alter column "created_at" drop not null;

-- Same for media_catalogue.id: drop identity if present, then set default to sequence.
ALTER TABLE IF EXISTS public.media_catalogue
  ALTER COLUMN id DROP IDENTITY IF EXISTS;
-- Only set the default if the sequence exists (guarded for idempotency).
DO $do$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE c.relkind = 'S' AND c.relname = 'media_catalogue_id_seq' AND n.nspname = 'public'
  ) THEN
    EXECUTE 'ALTER TABLE IF EXISTS public.media_catalogue ALTER COLUMN id SET DEFAULT nextval(''public.media_catalogue_id_seq''::regclass)';
  END IF;
END
$do$;

alter table "public"."media_catalogue" alter column "irn" set not null;

alter table "public"."media_catalogue" alter column "irn" set data type bigint using "irn"::bigint;

-- Guard these in case the sequence doesn't exist in the target DB.
ALTER SEQUENCE IF EXISTS public.biology_catalogue_id_seq OWNED BY public.biology_catalogue.id;

ALTER SEQUENCE IF EXISTS public.biology_taxonomy_id_seq OWNED BY public.biology_taxonomy.id;

ALTER SEQUENCE IF EXISTS public.media_catalogue_id_seq OWNED BY public.media_catalogue.id;

ALTER SEQUENCE IF EXISTS public.media_id_seq OWNED BY public.media.id;

ALTER SEQUENCE IF EXISTS public.mineralogy_catalogue_id_seq OWNED BY public.mineralogy_catalogue.id;

ALTER SEQUENCE IF EXISTS public.mineralogy_taxonomy_id_seq OWNED BY public.mineralogy_taxonomy.id;

drop sequence if exists "public"."history_catalogue_id_seq";

drop sequence if exists "public"."taxonomy_irn_seq";

drop type "public"."bio_departments";

drop type "public"."life_stages";

drop type "public"."sides";

drop type "public"."type_statuses";

drop extension if exists "btree_gin";

drop extension if exists "moddatetime";

drop extension if exists "pg_trgm";

CREATE UNIQUE INDEX biology_catalogue_irn_key ON public.biology_catalogue USING btree (irn);

CREATE UNIQUE INDEX biology_catalogue_pkey ON public.biology_catalogue USING btree (id);

CREATE UNIQUE INDEX biology_taxonomy_irn_key ON public.biology_taxonomy USING btree (irn);

CREATE UNIQUE INDEX biology_taxonomy_pkey ON public.biology_taxonomy USING btree (id);

CREATE UNIQUE INDEX media_catalogue_irn_key ON public.media_catalogue USING btree (irn);

CREATE UNIQUE INDEX mineralogy_catalogue_irn_key ON public.mineralogy_catalogue USING btree (irn);

CREATE UNIQUE INDEX mineralogy_catalogue_pkey ON public.mineralogy_catalogue USING btree (id);

CREATE UNIQUE INDEX mineralogy_catalogue_taxonomy_pkey ON public.mineralogy_catalogue_taxonomy USING btree (catalogue_irn, taxonomy_id);

CREATE UNIQUE INDEX mineralogy_taxonomy_irn_key ON public.mineralogy_taxonomy USING btree (irn);

CREATE UNIQUE INDEX mineralogy_taxonomy_pkey ON public.mineralogy_taxonomy USING btree (id);

alter table "public"."biology_catalogue" add constraint "biology_catalogue_pkey" PRIMARY KEY using index "biology_catalogue_pkey";

alter table "public"."biology_taxonomy" add constraint "biology_taxonomy_pkey" PRIMARY KEY using index "biology_taxonomy_pkey";

alter table "public"."mineralogy_catalogue" add constraint "mineralogy_catalogue_pkey" PRIMARY KEY using index "mineralogy_catalogue_pkey";

alter table "public"."mineralogy_catalogue_taxonomy" add constraint "mineralogy_catalogue_taxonomy_pkey" PRIMARY KEY using index "mineralogy_catalogue_taxonomy_pkey";

alter table "public"."mineralogy_taxonomy" add constraint "mineralogy_taxonomy_pkey" PRIMARY KEY using index "mineralogy_taxonomy_pkey";

alter table "public"."biology_catalogue" add constraint "biology_catalogue_irn_key" UNIQUE using index "biology_catalogue_irn_key";

alter table "public"."biology_catalogue" add constraint "fk_biology_catalogue_taxon_irn" FOREIGN KEY (taxon_irn) REFERENCES public.biology_taxonomy(irn) ON UPDATE CASCADE ON DELETE SET NULL not valid;

alter table "public"."biology_catalogue" validate constraint "fk_biology_catalogue_taxon_irn";

alter table "public"."biology_taxonomy" add constraint "biology_taxonomy_irn_key" UNIQUE using index "biology_taxonomy_irn_key";

alter table "public"."media_catalogue" add constraint "media_catalogue_irn_key" UNIQUE using index "media_catalogue_irn_key";

alter table "public"."mineralogy_catalogue" add constraint "mineralogy_catalogue_irn_key" UNIQUE using index "mineralogy_catalogue_irn_key";

alter table "public"."mineralogy_catalogue_taxonomy" add constraint "mineralogy_catalogue_taxonomy_catalogue_irn_fkey" FOREIGN KEY (catalogue_irn) REFERENCES public.mineralogy_catalogue(irn) not valid;

alter table "public"."mineralogy_catalogue_taxonomy" validate constraint "mineralogy_catalogue_taxonomy_catalogue_irn_fkey";

alter table "public"."mineralogy_catalogue_taxonomy" add constraint "mineralogy_catalogue_taxonomy_taxonomy_id_fkey" FOREIGN KEY (taxonomy_id) REFERENCES public.mineralogy_taxonomy(id) not valid;

alter table "public"."mineralogy_catalogue_taxonomy" validate constraint "mineralogy_catalogue_taxonomy_taxonomy_id_fkey";

alter table "public"."mineralogy_taxonomy" add constraint "mineralogy_taxonomy_irn_key" UNIQUE using index "mineralogy_taxonomy_irn_key";

alter table "public"."media_catalogue" add constraint "media_catalogue_media_id_fkey" FOREIGN KEY (media_id) REFERENCES public.media(id) not valid;

alter table "public"."media_catalogue" validate constraint "media_catalogue_media_id_fkey";

grant delete on table "public"."biology_catalogue" to "anon";

grant insert on table "public"."biology_catalogue" to "anon";

grant references on table "public"."biology_catalogue" to "anon";

grant select on table "public"."biology_catalogue" to "anon";

grant trigger on table "public"."biology_catalogue" to "anon";

grant truncate on table "public"."biology_catalogue" to "anon";

grant update on table "public"."biology_catalogue" to "anon";

grant delete on table "public"."biology_catalogue" to "authenticated";

grant insert on table "public"."biology_catalogue" to "authenticated";

grant references on table "public"."biology_catalogue" to "authenticated";

grant select on table "public"."biology_catalogue" to "authenticated";

grant trigger on table "public"."biology_catalogue" to "authenticated";

grant truncate on table "public"."biology_catalogue" to "authenticated";

grant update on table "public"."biology_catalogue" to "authenticated";

grant delete on table "public"."biology_catalogue" to "service_role";

grant insert on table "public"."biology_catalogue" to "service_role";

grant references on table "public"."biology_catalogue" to "service_role";

grant select on table "public"."biology_catalogue" to "service_role";

grant trigger on table "public"."biology_catalogue" to "service_role";

grant truncate on table "public"."biology_catalogue" to "service_role";

grant update on table "public"."biology_catalogue" to "service_role";

grant delete on table "public"."biology_taxonomy" to "anon";

grant insert on table "public"."biology_taxonomy" to "anon";

grant references on table "public"."biology_taxonomy" to "anon";

grant select on table "public"."biology_taxonomy" to "anon";

grant trigger on table "public"."biology_taxonomy" to "anon";

grant truncate on table "public"."biology_taxonomy" to "anon";

grant update on table "public"."biology_taxonomy" to "anon";

grant delete on table "public"."biology_taxonomy" to "authenticated";

grant insert on table "public"."biology_taxonomy" to "authenticated";

grant references on table "public"."biology_taxonomy" to "authenticated";

grant select on table "public"."biology_taxonomy" to "authenticated";

grant trigger on table "public"."biology_taxonomy" to "authenticated";

grant truncate on table "public"."biology_taxonomy" to "authenticated";

grant update on table "public"."biology_taxonomy" to "authenticated";

grant delete on table "public"."biology_taxonomy" to "service_role";

grant insert on table "public"."biology_taxonomy" to "service_role";

grant references on table "public"."biology_taxonomy" to "service_role";

grant select on table "public"."biology_taxonomy" to "service_role";

grant trigger on table "public"."biology_taxonomy" to "service_role";

grant truncate on table "public"."biology_taxonomy" to "service_role";

grant update on table "public"."biology_taxonomy" to "service_role";

grant delete on table "public"."mineralogy_catalogue" to "anon";

grant insert on table "public"."mineralogy_catalogue" to "anon";

grant references on table "public"."mineralogy_catalogue" to "anon";

grant select on table "public"."mineralogy_catalogue" to "anon";

grant trigger on table "public"."mineralogy_catalogue" to "anon";

grant truncate on table "public"."mineralogy_catalogue" to "anon";

grant update on table "public"."mineralogy_catalogue" to "anon";

grant delete on table "public"."mineralogy_catalogue" to "authenticated";

grant insert on table "public"."mineralogy_catalogue" to "authenticated";

grant references on table "public"."mineralogy_catalogue" to "authenticated";

grant select on table "public"."mineralogy_catalogue" to "authenticated";

grant trigger on table "public"."mineralogy_catalogue" to "authenticated";

grant truncate on table "public"."mineralogy_catalogue" to "authenticated";

grant update on table "public"."mineralogy_catalogue" to "authenticated";

grant delete on table "public"."mineralogy_catalogue" to "service_role";

grant insert on table "public"."mineralogy_catalogue" to "service_role";

grant references on table "public"."mineralogy_catalogue" to "service_role";

grant select on table "public"."mineralogy_catalogue" to "service_role";

grant trigger on table "public"."mineralogy_catalogue" to "service_role";

grant truncate on table "public"."mineralogy_catalogue" to "service_role";

grant update on table "public"."mineralogy_catalogue" to "service_role";

grant delete on table "public"."mineralogy_catalogue_taxonomy" to "anon";

grant insert on table "public"."mineralogy_catalogue_taxonomy" to "anon";

grant references on table "public"."mineralogy_catalogue_taxonomy" to "anon";

grant select on table "public"."mineralogy_catalogue_taxonomy" to "anon";

grant trigger on table "public"."mineralogy_catalogue_taxonomy" to "anon";

grant truncate on table "public"."mineralogy_catalogue_taxonomy" to "anon";

grant update on table "public"."mineralogy_catalogue_taxonomy" to "anon";

grant delete on table "public"."mineralogy_catalogue_taxonomy" to "authenticated";

grant insert on table "public"."mineralogy_catalogue_taxonomy" to "authenticated";

grant references on table "public"."mineralogy_catalogue_taxonomy" to "authenticated";

grant select on table "public"."mineralogy_catalogue_taxonomy" to "authenticated";

grant trigger on table "public"."mineralogy_catalogue_taxonomy" to "authenticated";

grant truncate on table "public"."mineralogy_catalogue_taxonomy" to "authenticated";

grant update on table "public"."mineralogy_catalogue_taxonomy" to "authenticated";

grant delete on table "public"."mineralogy_catalogue_taxonomy" to "service_role";

grant insert on table "public"."mineralogy_catalogue_taxonomy" to "service_role";

grant references on table "public"."mineralogy_catalogue_taxonomy" to "service_role";

grant select on table "public"."mineralogy_catalogue_taxonomy" to "service_role";

grant trigger on table "public"."mineralogy_catalogue_taxonomy" to "service_role";

grant truncate on table "public"."mineralogy_catalogue_taxonomy" to "service_role";

grant update on table "public"."mineralogy_catalogue_taxonomy" to "service_role";

grant delete on table "public"."mineralogy_taxonomy" to "anon";

grant insert on table "public"."mineralogy_taxonomy" to "anon";

grant references on table "public"."mineralogy_taxonomy" to "anon";

grant select on table "public"."mineralogy_taxonomy" to "anon";

grant trigger on table "public"."mineralogy_taxonomy" to "anon";

grant truncate on table "public"."mineralogy_taxonomy" to "anon";

grant update on table "public"."mineralogy_taxonomy" to "anon";

grant delete on table "public"."mineralogy_taxonomy" to "authenticated";

grant insert on table "public"."mineralogy_taxonomy" to "authenticated";

grant references on table "public"."mineralogy_taxonomy" to "authenticated";

grant select on table "public"."mineralogy_taxonomy" to "authenticated";

grant trigger on table "public"."mineralogy_taxonomy" to "authenticated";

grant truncate on table "public"."mineralogy_taxonomy" to "authenticated";

grant update on table "public"."mineralogy_taxonomy" to "authenticated";

grant delete on table "public"."mineralogy_taxonomy" to "service_role";

grant insert on table "public"."mineralogy_taxonomy" to "service_role";

grant references on table "public"."mineralogy_taxonomy" to "service_role";

grant select on table "public"."mineralogy_taxonomy" to "service_role";

grant trigger on table "public"."mineralogy_taxonomy" to "service_role";

grant truncate on table "public"."mineralogy_taxonomy" to "service_role";

grant update on table "public"."mineralogy_taxonomy" to "service_role";

-- Create handle_updated_at triggers only when the extension function exists
DO $do$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE p.proname = 'moddatetime' AND n.nspname = 'extensions'
  ) THEN
    -- biology_catalogue
    IF NOT EXISTS (
      SELECT 1 FROM pg_trigger t JOIN pg_class c ON t.tgrelid = c.oid
      WHERE t.tgname = 'handle_updated_at' AND c.relname = 'biology_catalogue'
    ) THEN
      EXECUTE 'CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.biology_catalogue FOR EACH ROW EXECUTE FUNCTION extensions.moddatetime(''updated_at'')';
    END IF;

    -- biology_taxonomy
    IF NOT EXISTS (
      SELECT 1 FROM pg_trigger t JOIN pg_class c ON t.tgrelid = c.oid
      WHERE t.tgname = 'handle_updated_at' AND c.relname = 'biology_taxonomy'
    ) THEN
      EXECUTE 'CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.biology_taxonomy FOR EACH ROW EXECUTE FUNCTION extensions.moddatetime(''updated_at'')';
    END IF;

    -- media
    IF NOT EXISTS (
      SELECT 1 FROM pg_trigger t JOIN pg_class c ON t.tgrelid = c.oid
      WHERE t.tgname = 'handle_updated_at' AND c.relname = 'media'
    ) THEN
      EXECUTE 'CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.media FOR EACH ROW EXECUTE FUNCTION extensions.moddatetime(''updated_at'')';
    END IF;

    -- media_catalogue
    IF NOT EXISTS (
      SELECT 1 FROM pg_trigger t JOIN pg_class c ON t.tgrelid = c.oid
      WHERE t.tgname = 'handle_updated_at' AND c.relname = 'media_catalogue'
    ) THEN
      EXECUTE 'CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.media_catalogue FOR EACH ROW EXECUTE FUNCTION extensions.moddatetime(''updated_at'')';
    END IF;

    -- mineralogy_catalogue
    IF NOT EXISTS (
      SELECT 1 FROM pg_trigger t JOIN pg_class c ON t.tgrelid = c.oid
      WHERE t.tgname = 'handle_updated_at' AND c.relname = 'mineralogy_catalogue'
    ) THEN
      EXECUTE 'CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.mineralogy_catalogue FOR EACH ROW EXECUTE FUNCTION extensions.moddatetime(''updated_at'')';
    END IF;

    -- mineralogy_taxonomy
    IF NOT EXISTS (
      SELECT 1 FROM pg_trigger t JOIN pg_class c ON t.tgrelid = c.oid
      WHERE t.tgname = 'handle_updated_at' AND c.relname = 'mineralogy_taxonomy'
    ) THEN
      EXECUTE 'CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.mineralogy_taxonomy FOR EACH ROW EXECUTE FUNCTION extensions.moddatetime(''updated_at'')';
    END IF;

    -- anthropology_catalogue
    IF NOT EXISTS (
      SELECT 1 FROM pg_trigger t JOIN pg_class c ON t.tgrelid = c.oid
      WHERE t.tgname = 'handle_updated_at' AND c.relname = 'anthropology_catalogue'
    ) THEN
      EXECUTE 'CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.anthropology_catalogue FOR EACH ROW EXECUTE FUNCTION extensions.moddatetime(''updated_at'')';
    END IF;

    -- anthropology_catalogue_cultures_join
    IF NOT EXISTS (
      SELECT 1 FROM pg_trigger t JOIN pg_class c ON t.tgrelid = c.oid
      WHERE t.tgname = 'handle_updated_at' AND c.relname = 'anthropology_catalogue_cultures_join'
    ) THEN
      EXECUTE 'CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.anthropology_catalogue_cultures_join FOR EACH ROW EXECUTE FUNCTION extensions.moddatetime(''updated_at'')';
    END IF;

    -- anthropology_cultures
    IF NOT EXISTS (
      SELECT 1 FROM pg_trigger t JOIN pg_class c ON t.tgrelid = c.oid
      WHERE t.tgname = 'handle_updated_at' AND c.relname = 'anthropology_cultures'
    ) THEN
      EXECUTE 'CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.anthropology_cultures FOR EACH ROW EXECUTE FUNCTION extensions.moddatetime(''updated_at'')';
    END IF;

  END IF; -- function exists
END
$do$;


