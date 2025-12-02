create extension if not exists "pg_net" with schema "extensions";

create extension if not exists "pgjwt" with schema "extensions";

-- Safely drop triggers that depend on the extensions.moddatetime() function
-- before attempting to drop the extension to avoid dependency errors (SQLSTATE 2BP01).
DO $do$
DECLARE
    trg RECORD;
    tbl text;
BEGIN
    FOR trg IN
        SELECT
            n.nspname AS table_schema,
            c.relname AS table_name,
            t.tgname AS trigger_name
        FROM pg_trigger t
        JOIN pg_class c ON t.tgrelid = c.oid
        JOIN pg_namespace n ON c.relnamespace = n.oid
        JOIN pg_proc p ON t.tgfoid = p.oid
        JOIN pg_namespace pn ON p.pronamespace = pn.oid
        WHERE pn.nspname = 'extensions'
            AND p.proname = 'moddatetime'
            AND NOT t.tgisinternal
    LOOP
        tbl := format('%I.%I', trg.table_schema, trg.table_name);
        EXECUTE format('DROP TRIGGER IF EXISTS %I ON %s;', trg.trigger_name, tbl);
    END LOOP;

    -- Now safe to drop the extension if present
    EXECUTE 'DROP EXTENSION IF EXISTS "moddatetime"';
END
$do$;

create extension if not exists "btree_gin" with schema "public";

create extension if not exists "moddatetime" with schema "public";

create extension if not exists "pg_trgm" with schema "public";

create type "public"."bio_departments" as enum ('herpetology', 'ornithology', 'mammalogy', 'entomology', 'malacology', 'ichthyology', 'dinosaur institute', 'rancho la brea', 'vertebrate paleontology', 'invertebrate paleontology', 'echinoderms', 'polychaetes');

create type "public"."life_stages" as enum ('tadpole', 'subadult', 'juvenile', 'pupae', 'pupa', 'adult', 'larvae', 'nymph', 'hatchling', 'triungulin', 'instar I', 'instar II', 'instar III', 'instar IV', 'instar V', 'instar VI', 'instar VII', 'instar VIII', 'egg');

create type "public"."sides" as enum ('left_right', 'right', 'left');

create type "public"."type_statuses" as enum ('holotype', 'hypotype', 'paratype', 'figured', 'syntype', 'allotype', 'lectotype', 'paralectotype', 'neotype');

create sequence "public"."biology_elements_id_seq";

create sequence "public"."history_catalogue_id_seq";

create sequence "public"."mineralogy_specimens_id_seq";

drop trigger if exists "handle_updated_at" on "public"."media";

drop trigger if exists "handle_updated_at" on "public"."media_catalogue";

drop trigger if exists "handle_updated_at" on "public"."anthropology_catalogue";

drop trigger if exists "handle_updated_at" on "public"."anthropology_catalogue_cultures_join";

drop trigger if exists "handle_updated_at" on "public"."anthropology_cultures";

drop trigger if exists "handle_updated_at" on "public"."biology_catalogue";

drop trigger if exists "handle_updated_at" on "public"."biology_taxonomy";

drop trigger if exists "handle_updated_at" on "public"."mineralogy_catalogue";

drop trigger if exists "handle_updated_at" on "public"."mineralogy_taxonomy";

alter table "public"."media_catalogue" drop constraint "media_catalogue_irn_key";

alter table "public"."media_catalogue" drop constraint "media_catalogue_media_id_fkey";

drop index if exists "public"."media_catalogue_irn_key";


  create table "public"."biology_catalogue_elements" (
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "catalogue_irn" bigint not null,
    "element_id" bigint not null
      );



  create table "public"."biology_elements" (
    "id" bigint not null default nextval('public.biology_elements_id_seq'::regclass),
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "name" text not null,
    "parent_id" bigint,
    "domains" text[],
    "synonyms" text[],
    "uberon_id" text,
    "description" text
      );


alter table "public"."biology_elements" enable row level security;


  create table "public"."history_catalogue" (
    "id" integer not null default nextval('public.history_catalogue_id_seq'::regclass),
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "date_emu_record_modified" date,
    "date_emu_record_inserted" date,
    "irn" bigint not null,
    "emu_guid" uuid not null,
    "catalogue_number" text,
    "department" text,
    "section" text,
    "collection_name" text,
    "form" text,
    "description" text,
    "level_of_description" text,
    "title" text,
    "date_created" text,
    "subjects" jsonb,
    "creators" jsonb
      );


alter table "public"."history_catalogue" enable row level security;


  create table "public"."mineralogy_specimens" (
    "id" integer not null default nextval('public.mineralogy_specimens_id_seq'::regclass),
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "specimen_id" uuid not null,
    "catalogue_irn" bigint,
    "taxonomy_irn" bigint,
    "is_primary_specimen" boolean,
    "is_display_quality" boolean,
    "verbatim_colors" text,
    "colors" text[],
    "habit" text,
    "variety" text
      );


alter table "public"."mineralogy_specimens" enable row level security;

ALTER TABLE IF EXISTS public.biology_catalogue DROP COLUMN IF EXISTS element;

-- Add the new column only if it does not already exist to make this migration idempotent
ALTER TABLE IF EXISTS public.biology_catalogue ADD COLUMN IF NOT EXISTS verbatim_element text;

alter table "public"."biology_taxonomy" add column "emu_guid" uuid;

alter table "public"."biology_taxonomy" alter column "current_name_irn" set data type bigint using "current_name_irn"::bigint;

alter table "public"."media" drop column "publish_to_collection_page";

alter table "public"."media" drop column "updated_at";

alter table "public"."media" drop column "uploaded_datetime";

alter table "public"."media" add column "department" text;

alter table "public"."media" add column "publish_to_collection_pages" boolean default true;

alter table "public"."media" add column "uploaded" date;

alter table "public"."media" alter column "created_at" set not null;

alter table "public"."media" alter column "dams_id" set data type integer using "dams_id"::integer;

alter table "public"."media" alter column "id" drop default;

alter table "public"."media" alter column "id" add generated by default as identity;

alter table "public"."media" alter column "is_authoritative" drop default;

alter table "public"."media_catalogue" drop column "updated_at";

alter table "public"."media_catalogue" alter column "created_at" set not null;

alter table "public"."media_catalogue" alter column "id" drop default;

alter table "public"."media_catalogue" alter column "id" add generated by default as identity;

alter table "public"."media_catalogue" alter column "irn" drop not null;

alter table "public"."media_catalogue" alter column "irn" set data type integer using "irn"::integer;

alter table "public"."mineralogy_catalogue" drop column "specimens";

alter sequence "public"."biology_elements_id_seq" owned by "public"."biology_elements"."id";

alter sequence "public"."history_catalogue_id_seq" owned by "public"."history_catalogue"."id";

alter sequence "public"."mineralogy_specimens_id_seq" owned by "public"."mineralogy_specimens"."id";

drop sequence if exists "public"."media_catalogue_id_seq";

drop sequence if exists "public"."media_id_seq";

CREATE UNIQUE INDEX biology_catalogue_elements_pkey ON public.biology_catalogue_elements USING btree (catalogue_irn, element_id);

CREATE UNIQUE INDEX biology_elements_pkey ON public.biology_elements USING btree (id);

CREATE UNIQUE INDEX history_catalogue_irn_key ON public.history_catalogue USING btree (irn);

CREATE UNIQUE INDEX history_catalogue_pkey ON public.history_catalogue USING btree (id);

CREATE UNIQUE INDEX media_id_key ON public.media USING btree (id);

CREATE UNIQUE INDEX mineralogy_specimens_pkey ON public.mineralogy_specimens USING btree (id);

CREATE UNIQUE INDEX mineralogy_specimens_specimen_id_key ON public.mineralogy_specimens USING btree (specimen_id);

alter table "public"."biology_catalogue_elements" add constraint "biology_catalogue_elements_pkey" PRIMARY KEY using index "biology_catalogue_elements_pkey";

alter table "public"."biology_elements" add constraint "biology_elements_pkey" PRIMARY KEY using index "biology_elements_pkey";

alter table "public"."history_catalogue" add constraint "history_catalogue_pkey" PRIMARY KEY using index "history_catalogue_pkey";

alter table "public"."mineralogy_specimens" add constraint "mineralogy_specimens_pkey" PRIMARY KEY using index "mineralogy_specimens_pkey";

alter table "public"."biology_catalogue_elements" add constraint "biology_catalogue_elements_catalogue_irn_fkey" FOREIGN KEY (catalogue_irn) REFERENCES public.biology_catalogue(irn) not valid;

alter table "public"."biology_catalogue_elements" validate constraint "biology_catalogue_elements_catalogue_irn_fkey";

alter table "public"."biology_catalogue_elements" add constraint "biology_catalogue_elements_element_id_fkey" FOREIGN KEY (element_id) REFERENCES public.biology_elements(id) not valid;

alter table "public"."biology_catalogue_elements" validate constraint "biology_catalogue_elements_element_id_fkey";

alter table "public"."history_catalogue" add constraint "history_catalogue_irn_key" UNIQUE using index "history_catalogue_irn_key";

alter table "public"."media" add constraint "media_id_key" UNIQUE using index "media_id_key";

alter table "public"."mineralogy_specimens" add constraint "mineralogy_specimens_catalogue_irn_fkey" FOREIGN KEY (catalogue_irn) REFERENCES public.mineralogy_catalogue(irn) not valid;

alter table "public"."mineralogy_specimens" validate constraint "mineralogy_specimens_catalogue_irn_fkey";

alter table "public"."mineralogy_specimens" add constraint "mineralogy_specimens_specimen_id_key" UNIQUE using index "mineralogy_specimens_specimen_id_key";

alter table "public"."mineralogy_specimens" add constraint "mineralogy_specimens_taxonomy_irn_fkey" FOREIGN KEY (taxonomy_irn) REFERENCES public.mineralogy_taxonomy(irn) not valid;

alter table "public"."mineralogy_specimens" validate constraint "mineralogy_specimens_taxonomy_irn_fkey";

alter table "public"."media_catalogue" add constraint "media_catalogue_media_id_fkey" FOREIGN KEY (media_id) REFERENCES public.media(id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."media_catalogue" validate constraint "media_catalogue_media_id_fkey";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.get_department(irn_value integer)
 RETURNS text
 LANGUAGE plpgsql
AS $function$DECLARE 
  record text;
BEGIN 
  SELECT department
  INTO record
  FROM public.organisms
  WHERE irn = irn_value;
  RETURN record;
END;$function$
;

CREATE OR REPLACE FUNCTION public.get_distinct_values(column_name text, table_name text)
 RETURNS json
 LANGUAGE plpgsql
AS $function$DECLARE
    result json;
    query text;
BEGIN
    -- Construct the dynamic SQL query to return counts of distinct values as JSON, excluding NULLs
    query := format('
        SELECT jsonb_object_agg(value, count) 
        FROM (
            SELECT %I AS value, count(*) AS count 
            FROM %I 
            WHERE %I IS NOT NULL
            GROUP BY %I
        ) AS subquery', column_name, table_name, column_name, column_name);
    
    -- Execute the dynamic SQL and store the result in the result variable
    EXECUTE query INTO result;

    RETURN result;
END;$function$
;

CREATE OR REPLACE FUNCTION public.search(search_term text)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$DECLARE
    taxonomy_results JSONB;
    organisms_results JSONB;
    combined_results JSONB;
BEGIN
    -- Call the taxonomy search function
    taxonomy_results := search_taxonomy(search_term);

    -- Call the organisms search function
    organisms_results := search_organisms(search_term);

    -- Combine the results and sort by relevance
    WITH combined_data AS (
        SELECT taxonomy_element AS data
        FROM JSONB_ARRAY_ELEMENTS(taxonomy_results) AS taxonomy_element
        UNION ALL
        SELECT organisms_element AS data
        FROM JSONB_ARRAY_ELEMENTS(organisms_results) AS organisms_element
    ),
    sorted_data AS (
        SELECT data
        FROM combined_data
        ORDER BY (data->>'relevance')::NUMERIC DESC
    )
    SELECT JSONB_AGG(data)
    INTO combined_results
    FROM sorted_data;

    -- Return the combined and sorted results
    RETURN COALESCE(combined_results, '[]'::JSONB);
END;$function$
;

CREATE OR REPLACE FUNCTION public.search_organisms(search_term text)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$DECLARE
    result JSONB;
BEGIN
    -- Precompute search vector and query for catalogue_number
    WITH search_data AS (
        SELECT
            irn,
            catalogue_number,
            department,
            -- Create a full-text search vector for catalogue_number
            to_tsvector('english', catalogue_number) AS search_vector,
            -- Create a full-text search query from the input search_term with prefix matching
            to_tsquery('english', regexp_replace(trim(search_term), '\s+', ' & ', 'g') || ':*') AS query
        FROM organisms
    ),
    ranked_data AS (
        SELECT
            irn,
            catalogue_number,
            department,
            -- Calculate relevance for catalogue_number using full-text search
            ts_rank(search_vector, query) AS base_relevance,
            -- Boost for exact matches in irn or catalogue_number
            CASE
                WHEN CAST(irn AS TEXT) = search_term THEN 1.0
                WHEN LOWER(TRIM(catalogue_number)) = LOWER(TRIM(search_term)) THEN 1.0
                ELSE 0.0
            END AS exact_match_boost,
            -- Trigram similarity for fuzzy matching
            similarity(catalogue_number, search_term) AS trigram_similarity,
            -- Identify which field matched
            CASE
                WHEN CAST(irn AS TEXT) = search_term THEN 'irn'
                WHEN to_tsvector('english', catalogue_number) @@ query THEN 'catalogueNumber'
                ELSE 'unknown'
            END AS matched_field
        FROM search_data
        -- Filter rows where search_vector matches query or irn matches exactly
        WHERE search_vector @@ query OR CAST(irn AS TEXT) = search_term
    )
    -- Aggregate the top results into a JSONB array
    SELECT JSONB_AGG(
        JSONB_BUILD_OBJECT(
            'table', 'organisms',
            'matchedField', matched_field,
            'searchTerm', search_term,
            -- Total relevance is the sum of base relevance, exact match boost, and trigram similarity
            'relevance', base_relevance + exact_match_boost + trigram_similarity,
            'attributes', JSON_BUILD_OBJECT(
                'irn', irn,
                'catalogueNumber', catalogue_number,
                'department', department
            )
        )
    )
    INTO result
    FROM (
        -- Sort by total relevance and limit to top 10 matches
        SELECT *
        FROM ranked_data
        ORDER BY base_relevance + exact_match_boost + trigram_similarity DESC
        LIMIT 10
    ) sorted_data;

    -- Return the results as JSONB, or an empty array if no matches are found
    RETURN COALESCE(result, '[]'::JSONB);
END;$function$
;

CREATE OR REPLACE FUNCTION public.search_taxonomy(search_term text)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$DECLARE
    result JSONB;
BEGIN
    -- Precompute search vector and tsquery for readability and reuse
    WITH search_data AS (
        SELECT 
            irn,
            taxon,
            vernacular_name,
            taxon_rank,
            department,
            COALESCE(to_tsvector('english', taxon || ' ' || vernacular_name), to_tsvector('english', '')) AS search_vector,
            COALESCE(to_tsquery('english', regexp_replace(trim(search_term), '\s+', ' & ', 'g') || ':*'), to_tsquery('english', '')) AS query
        FROM taxonomy
    ),
    ranked_data AS (
        SELECT 
            irn,
            taxon,
            vernacular_name,
            taxon_rank,
            department,
            COALESCE(ts_rank(search_vector, query), 0.0) AS base_relevance,
            CASE
                WHEN LOWER(TRIM(taxon)) = LOWER(TRIM(search_term)) THEN 1.0
                WHEN LOWER(TRIM(vernacular_name)) = LOWER(TRIM(search_term)) THEN 1.0
                ELSE 0.0
            END AS exact_match_boost,
            -- Trigram similarity for fuzzy matching
            GREATEST(similarity(taxon, search_term), similarity(vernacular_name, search_term)) AS trigram_similarity,
            CASE
                WHEN LOWER(TRIM(taxon)) = LOWER(TRIM(search_term)) THEN 'taxon'
                WHEN LOWER(TRIM(vernacular_name)) = LOWER(TRIM(search_term)) THEN 'vernacularName'
                WHEN to_tsvector('english', taxon) @@ query THEN 'taxon'
                WHEN to_tsvector('english', vernacular_name) @@ query THEN 'vernacularName'
                ELSE 'unknown'
            END AS matched_field
        FROM search_data
        WHERE 
            -- Include records where full-text search matches
            search_vector @@ query
            -- OR partial matches using ILIKE
            OR taxon ILIKE '%' || search_term || '%'
            OR vernacular_name ILIKE '%' || search_term || '%'
            -- OR exact matches
            OR LOWER(TRIM(taxon)) = LOWER(TRIM(search_term))
            OR LOWER(TRIM(vernacular_name)) = LOWER(TRIM(search_term))
    )
    -- Perform sorting and limit before aggregation
    SELECT JSONB_AGG(
        JSONB_BUILD_OBJECT(
            'table', 'taxonomy',
            'searchTerm', search_term,
            'matchedField', matched_field,
            'relevance', base_relevance + exact_match_boost + trigram_similarity,
            'attributes', JSONB_BUILD_OBJECT(
                'irn', irn,
                'department', department,
                'taxon', taxon,
                'vernacularName', vernacular_name,
                'taxonRank', taxon_rank
            )
        )
    )
    INTO result
    FROM (
        SELECT *
        FROM ranked_data
        ORDER BY base_relevance + exact_match_boost + trigram_similarity DESC
        LIMIT 10
    ) sorted_data;

    -- Return the results as a JSONB array, or an empty array if no matches are found
    RETURN COALESCE(result, '[]'::JSONB);
END;$function$
;

grant delete on table "public"."biology_catalogue_elements" to "anon";

grant insert on table "public"."biology_catalogue_elements" to "anon";

grant references on table "public"."biology_catalogue_elements" to "anon";

grant select on table "public"."biology_catalogue_elements" to "anon";

grant trigger on table "public"."biology_catalogue_elements" to "anon";

grant truncate on table "public"."biology_catalogue_elements" to "anon";

grant update on table "public"."biology_catalogue_elements" to "anon";

grant delete on table "public"."biology_catalogue_elements" to "authenticated";

grant insert on table "public"."biology_catalogue_elements" to "authenticated";

grant references on table "public"."biology_catalogue_elements" to "authenticated";

grant select on table "public"."biology_catalogue_elements" to "authenticated";

grant trigger on table "public"."biology_catalogue_elements" to "authenticated";

grant truncate on table "public"."biology_catalogue_elements" to "authenticated";

grant update on table "public"."biology_catalogue_elements" to "authenticated";

grant delete on table "public"."biology_catalogue_elements" to "service_role";

grant insert on table "public"."biology_catalogue_elements" to "service_role";

grant references on table "public"."biology_catalogue_elements" to "service_role";

grant select on table "public"."biology_catalogue_elements" to "service_role";

grant trigger on table "public"."biology_catalogue_elements" to "service_role";

grant truncate on table "public"."biology_catalogue_elements" to "service_role";

grant update on table "public"."biology_catalogue_elements" to "service_role";

grant delete on table "public"."biology_elements" to "anon";

grant insert on table "public"."biology_elements" to "anon";

grant references on table "public"."biology_elements" to "anon";

grant select on table "public"."biology_elements" to "anon";

grant trigger on table "public"."biology_elements" to "anon";

grant truncate on table "public"."biology_elements" to "anon";

grant update on table "public"."biology_elements" to "anon";

grant delete on table "public"."biology_elements" to "authenticated";

grant insert on table "public"."biology_elements" to "authenticated";

grant references on table "public"."biology_elements" to "authenticated";

grant select on table "public"."biology_elements" to "authenticated";

grant trigger on table "public"."biology_elements" to "authenticated";

grant truncate on table "public"."biology_elements" to "authenticated";

grant update on table "public"."biology_elements" to "authenticated";

grant delete on table "public"."biology_elements" to "service_role";

grant insert on table "public"."biology_elements" to "service_role";

grant references on table "public"."biology_elements" to "service_role";

grant select on table "public"."biology_elements" to "service_role";

grant trigger on table "public"."biology_elements" to "service_role";

grant truncate on table "public"."biology_elements" to "service_role";

grant update on table "public"."biology_elements" to "service_role";

grant delete on table "public"."history_catalogue" to "anon";

grant insert on table "public"."history_catalogue" to "anon";

grant references on table "public"."history_catalogue" to "anon";

grant select on table "public"."history_catalogue" to "anon";

grant trigger on table "public"."history_catalogue" to "anon";

grant truncate on table "public"."history_catalogue" to "anon";

grant update on table "public"."history_catalogue" to "anon";

grant delete on table "public"."history_catalogue" to "authenticated";

grant insert on table "public"."history_catalogue" to "authenticated";

grant references on table "public"."history_catalogue" to "authenticated";

grant select on table "public"."history_catalogue" to "authenticated";

grant trigger on table "public"."history_catalogue" to "authenticated";

grant truncate on table "public"."history_catalogue" to "authenticated";

grant update on table "public"."history_catalogue" to "authenticated";

grant delete on table "public"."history_catalogue" to "service_role";

grant insert on table "public"."history_catalogue" to "service_role";

grant references on table "public"."history_catalogue" to "service_role";

grant select on table "public"."history_catalogue" to "service_role";

grant trigger on table "public"."history_catalogue" to "service_role";

grant truncate on table "public"."history_catalogue" to "service_role";

grant update on table "public"."history_catalogue" to "service_role";

grant delete on table "public"."mineralogy_specimens" to "anon";

grant insert on table "public"."mineralogy_specimens" to "anon";

grant references on table "public"."mineralogy_specimens" to "anon";

grant select on table "public"."mineralogy_specimens" to "anon";

grant trigger on table "public"."mineralogy_specimens" to "anon";

grant truncate on table "public"."mineralogy_specimens" to "anon";

grant update on table "public"."mineralogy_specimens" to "anon";

grant delete on table "public"."mineralogy_specimens" to "authenticated";

grant insert on table "public"."mineralogy_specimens" to "authenticated";

grant references on table "public"."mineralogy_specimens" to "authenticated";

grant select on table "public"."mineralogy_specimens" to "authenticated";

grant trigger on table "public"."mineralogy_specimens" to "authenticated";

grant truncate on table "public"."mineralogy_specimens" to "authenticated";

grant update on table "public"."mineralogy_specimens" to "authenticated";

grant delete on table "public"."mineralogy_specimens" to "service_role";

grant insert on table "public"."mineralogy_specimens" to "service_role";

grant references on table "public"."mineralogy_specimens" to "service_role";

grant select on table "public"."mineralogy_specimens" to "service_role";

grant trigger on table "public"."mineralogy_specimens" to "service_role";

grant truncate on table "public"."mineralogy_specimens" to "service_role";

grant update on table "public"."mineralogy_specimens" to "service_role";

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.biology_elements FOR EACH ROW EXECUTE FUNCTION public.moddatetime('updated_at');

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.history_catalogue FOR EACH ROW EXECUTE FUNCTION public.moddatetime('updated_at');

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.mineralogy_specimens FOR EACH ROW EXECUTE FUNCTION public.moddatetime('updated_at');

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.anthropology_catalogue FOR EACH ROW EXECUTE FUNCTION public.moddatetime('updated_at');

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.anthropology_catalogue_cultures_join FOR EACH ROW EXECUTE FUNCTION public.moddatetime('updated_at');

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.anthropology_cultures FOR EACH ROW EXECUTE FUNCTION public.moddatetime('updated_at');

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.biology_catalogue FOR EACH ROW EXECUTE FUNCTION public.moddatetime('updated_at');

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.biology_taxonomy FOR EACH ROW EXECUTE FUNCTION public.moddatetime('updated_at');

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.mineralogy_catalogue FOR EACH ROW EXECUTE FUNCTION public.moddatetime('updated_at');

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.mineralogy_taxonomy FOR EACH ROW EXECUTE FUNCTION public.moddatetime('updated_at');



