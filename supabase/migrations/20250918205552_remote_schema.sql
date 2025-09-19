
SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE EXTENSION IF NOT EXISTS "pgsodium";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "btree_gin" WITH SCHEMA "public";






CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pg_trgm" WITH SCHEMA "public";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE TYPE "public"."bio_departments" AS ENUM (
    'herpetology',
    'ornithology',
    'mammalogy',
    'entomology',
    'malacology',
    'ichthyology',
    'dinosaur institute',
    'rancho la brea',
    'vertebrate paleontology',
    'invertebrate paleontology',
    'echinoderms',
    'polychaetes'
);


ALTER TYPE "public"."bio_departments" OWNER TO "postgres";


CREATE TYPE "public"."life_stages" AS ENUM (
    'tadpole',
    'subadult',
    'juvenile',
    'pupae',
    'pupa',
    'adult',
    'larvae',
    'nymph',
    'hatchling',
    'triungulin',
    'instar I',
    'instar II',
    'instar III',
    'instar IV',
    'instar V',
    'instar VI',
    'instar VII',
    'instar VIII',
    'egg'
);


ALTER TYPE "public"."life_stages" OWNER TO "postgres";


CREATE TYPE "public"."sides" AS ENUM (
    'left_right',
    'right',
    'left'
);


ALTER TYPE "public"."sides" OWNER TO "postgres";


CREATE TYPE "public"."type_statuses" AS ENUM (
    'holotype',
    'hypotype',
    'paratype',
    'figured',
    'syntype',
    'allotype',
    'lectotype',
    'paralectotype',
    'neotype'
);


ALTER TYPE "public"."type_statuses" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_department"("irn_value" integer) RETURNS "text"
    LANGUAGE "plpgsql"
    AS $$DECLARE 
  record text;
BEGIN 
  SELECT department
  INTO record
  FROM public.organisms
  WHERE irn = irn_value;
  RETURN record;
END;$$;


ALTER FUNCTION "public"."get_department"("irn_value" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_distinct_values"("column_name" "text", "table_name" "text") RETURNS "json"
    LANGUAGE "plpgsql"
    AS $$DECLARE
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
END;$$;


ALTER FUNCTION "public"."get_distinct_values"("column_name" "text", "table_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."search"("search_term" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$DECLARE
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
END;$$;


ALTER FUNCTION "public"."search"("search_term" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."search_organisms"("search_term" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$DECLARE
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
END;$$;


ALTER FUNCTION "public"."search_organisms"("search_term" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."search_taxonomy"("search_term" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$DECLARE
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
END;$$;


ALTER FUNCTION "public"."search_taxonomy"("search_term" "text") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."anthropology_catalogue" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "irn" bigint NOT NULL,
    "date_emu_record_modified" "date",
    "date_emu_record_inserted" "date",
    "emu_guid" "uuid",
    "catalogue_number" "text",
    "creator" "text",
    "date_collected" "text",
    "date_received" "text",
    "description" "text",
    "object_name" "text",
    "material_type_verbatim" "text"[],
    "date_created" "text",
    "provenience_verbatim" "text",
    "department" "text",
    "section" "text",
    "collectors" "jsonb"[],
    "donors" "jsonb"[],
    "sites" "jsonb"[],
    "diameter" numeric,
    "height" numeric,
    "length" numeric,
    "width" numeric,
    "measurement_notes" "text",
    "commentary" "text",
    "cultural_attribution" "text",
    "site_summary" "text",
    "site_number" "text",
    "site_name" "text",
    "site_irn" bigint,
    "material_type" "jsonb"
);


ALTER TABLE "public"."anthropology_catalogue" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."anthropology_catalogue_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "public"."anthropology_catalogue_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."anthropology_catalogue_id_seq" OWNED BY "public"."anthropology_catalogue"."id";



CREATE TABLE IF NOT EXISTS "public"."anthropology_cultures" (
    "id" bigint NOT NULL,
    "name" "text" NOT NULL,
    "type" "text",
    "region" "text",
    "parent_id" bigint,
    "age_start" integer,
    "age_end" integer,
    "synonyms" "text"[],
    "endonyms" "text"[],
    "aat_id" "text",
    "wikidata_id" "text",
    "aat_notes" "text",
    "description" "text",
    "airtable_id" "text"
);


ALTER TABLE "public"."anthropology_cultures" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."media" (
    "id" bigint NOT NULL,
    "dams_id" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "department" "text",
    "source" "text",
    "format" "text",
    "url" "text",
    "title" "text",
    "description" "text",
    "uploaded" "date",
    "creator" "text",
    "license" "text",
    "type" "text",
    "publish_to_collection_pages" boolean DEFAULT true,
    "is_authoritative" boolean
);


ALTER TABLE "public"."media" OWNER TO "postgres";


COMMENT ON COLUMN "public"."media"."publish_to_collection_pages" IS 'Boolean if media asset should be included in collection pages';



COMMENT ON COLUMN "public"."media"."is_authoritative" IS 'Determines if record should be used as the thumbnail and main photo of the catalogue record.';



CREATE TABLE IF NOT EXISTS "public"."media_catalogue" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "media_id" bigint,
    "irn" integer,
    "domain" "text"
);


ALTER TABLE "public"."media_catalogue" OWNER TO "postgres";


ALTER TABLE "public"."media_catalogue" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."media_catalogue_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



ALTER TABLE "public"."media" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."media_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."minerals" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "irn" integer NOT NULL,
    "catalogue_number" "text",
    "date_emu_record_modified" "date",
    "emu_guid" "text",
    "category" "text",
    "dimensions" real[],
    "quantity" integer,
    "verbatim_size" "text",
    "size" "text"[],
    "jewelry" "text"[],
    "variety" "text"[],
    "habit" "text"[],
    "is_display_quality" boolean,
    "color" "text"[],
    "description" "text"
);


ALTER TABLE "public"."minerals" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."minerals_catalogue_taxonomy_join" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "irn" integer,
    "taxon_irn" integer
);


ALTER TABLE "public"."minerals_catalogue_taxonomy_join" OWNER TO "postgres";


ALTER TABLE "public"."minerals_catalogue_taxonomy_join" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."minerals_catalogue_taxonomy_join_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



ALTER TABLE "public"."minerals" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."minerals_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."minerals_taxonomy" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "irn" integer NOT NULL,
    "mindat_id" integer,
    "species" "text",
    "group" "text",
    "formula" "text",
    "is_valid" boolean,
    "crystal_system" "text",
    "mindat_name" "text",
    "mindat_formula" "text",
    "mindat_ima_status" "text"[],
    "mindat_variety_of" integer,
    "mindat_syn_id" integer,
    "mindat_group_id" integer,
    "mindat_entry_type" "text",
    "mindat_description" "text",
    "mindat_elements" "text"[],
    "mindat_strunz_1" "text",
    "mindat_strunz_2" "text",
    "mindat_strunz_3" "text",
    "mindat_strunz_4" "text",
    "mindat_dana_1" "text",
    "mindat_dana_2" "text",
    "mindat_dana_3" "text",
    "mindat_dana_4" "text",
    "mindat_rock_parent" integer,
    "mindat_rock_grandparent" integer
);


ALTER TABLE "public"."minerals_taxonomy" OWNER TO "postgres";


ALTER TABLE "public"."minerals_taxonomy" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."minerals_taxonomy_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."organisms" (
    "irn" integer NOT NULL,
    "department" "public"."bio_departments",
    "sex" "text",
    "caste" "text",
    "side" "public"."sides",
    "element" "text",
    "locality" "text",
    "basis_of_record" "text",
    "catalogue_number" "text",
    "date_emu_record_modified" "date",
    "emu_guid" "text",
    "life_stage" "public"."life_stages",
    "locality_irn" integer,
    "taxon_irn" integer,
    "type_status" "public"."type_statuses"
);


ALTER TABLE "public"."organisms" OWNER TO "postgres";


COMMENT ON COLUMN "public"."organisms"."locality" IS 'Locality summary data';



CREATE TABLE IF NOT EXISTS "public"."taxonomy" (
    "irn" integer NOT NULL,
    "department" "public"."bio_departments",
    "taxon" "text",
    "taxon_id" integer,
    "accepted_name_usage_id" integer,
    "canonical_name" "text",
    "generic_name" "text",
    "specific_epithet" "text",
    "infraspecific_epithet" "text",
    "taxon_rank" "text",
    "kingdom" "text",
    "phylum" "text",
    "class" "text",
    "order" "text",
    "family" "text",
    "genus" "text",
    "vernacular_name" "text",
    "source" "text",
    "weight" integer,
    "similarity" real
);


ALTER TABLE "public"."taxonomy" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."taxonomy_irn_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "public"."taxonomy_irn_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."taxonomy_irn_seq" OWNED BY "public"."taxonomy"."irn";



ALTER TABLE ONLY "public"."anthropology_catalogue" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."anthropology_catalogue_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."taxonomy" ALTER COLUMN "irn" SET DEFAULT "nextval"('"public"."taxonomy_irn_seq"'::"regclass");



ALTER TABLE ONLY "public"."anthropology_catalogue"
    ADD CONSTRAINT "anthropology_catalogue_irn_key" UNIQUE ("irn");



ALTER TABLE ONLY "public"."anthropology_catalogue"
    ADD CONSTRAINT "anthropology_catalogue_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."anthropology_cultures"
    ADD CONSTRAINT "anthropology_cultures_airtable_id_key" UNIQUE ("airtable_id");



ALTER TABLE ONLY "public"."anthropology_cultures"
    ADD CONSTRAINT "anthropology_cultures_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."media_catalogue"
    ADD CONSTRAINT "media_catalogue_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."media"
    ADD CONSTRAINT "media_dams_id_key" UNIQUE ("dams_id");



ALTER TABLE ONLY "public"."media"
    ADD CONSTRAINT "media_id_key" UNIQUE ("id");



ALTER TABLE ONLY "public"."media"
    ADD CONSTRAINT "media_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."minerals_catalogue_taxonomy_join"
    ADD CONSTRAINT "minerals_catalogue_taxonomy_join_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."minerals"
    ADD CONSTRAINT "minerals_irn_key" UNIQUE ("irn");



ALTER TABLE ONLY "public"."minerals"
    ADD CONSTRAINT "minerals_pkey" PRIMARY KEY ("id", "irn");



ALTER TABLE ONLY "public"."minerals_taxonomy"
    ADD CONSTRAINT "minerals_taxonomy_irn_key" UNIQUE ("irn");



ALTER TABLE ONLY "public"."minerals_taxonomy"
    ADD CONSTRAINT "minerals_taxonomy_pkey" PRIMARY KEY ("id", "irn");



ALTER TABLE ONLY "public"."organisms"
    ADD CONSTRAINT "organisms_pkey" PRIMARY KEY ("irn");



ALTER TABLE ONLY "public"."taxonomy"
    ADD CONSTRAINT "taxonomy_pkey" PRIMARY KEY ("irn");



CREATE INDEX "search_index" ON "public"."organisms" USING "gin" ("irn", "catalogue_number");



CREATE OR REPLACE TRIGGER "tsvector_update" BEFORE INSERT OR UPDATE ON "public"."organisms" FOR EACH ROW EXECUTE FUNCTION "tsvector_update_trigger"('search', 'pg_catalog.english', 'taxon', 'vernacularname');



ALTER TABLE ONLY "public"."media_catalogue"
    ADD CONSTRAINT "media_catalogue_media_id_fkey" FOREIGN KEY ("media_id") REFERENCES "public"."media"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."minerals_catalogue_taxonomy_join"
    ADD CONSTRAINT "minerals_catalogue_taxonomy_join_irn_fkey" FOREIGN KEY ("irn") REFERENCES "public"."minerals"("irn") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."minerals_catalogue_taxonomy_join"
    ADD CONSTRAINT "minerals_catalogue_taxonomy_join_taxon_irn_fkey" FOREIGN KEY ("taxon_irn") REFERENCES "public"."minerals_taxonomy"("irn") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."organisms"
    ADD CONSTRAINT "organisms_taxon_irn_fkey" FOREIGN KEY ("taxon_irn") REFERENCES "public"."taxonomy"("irn");



CREATE POLICY "Enable read access for all users" ON "public"."organisms" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."taxonomy" FOR SELECT USING (true);



ALTER TABLE "public"."anthropology_catalogue" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."anthropology_cultures" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."media" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."media_catalogue" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."minerals" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."minerals_catalogue_taxonomy_join" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."minerals_taxonomy" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."organisms" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."taxonomy" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_in"("cstring") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_in"("cstring") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_in"("cstring") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_in"("cstring") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_out"("public"."gtrgm") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_out"("public"."gtrgm") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_out"("public"."gtrgm") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_out"("public"."gtrgm") TO "service_role";




















































































































































































GRANT ALL ON FUNCTION "public"."get_department"("irn_value" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_department"("irn_value" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_department"("irn_value" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_distinct_values"("column_name" "text", "table_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_distinct_values"("column_name" "text", "table_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_distinct_values"("column_name" "text", "table_name" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_btree_consistent"("internal", smallint, "anyelement", integer, "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_btree_consistent"("internal", smallint, "anyelement", integer, "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_btree_consistent"("internal", smallint, "anyelement", integer, "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_btree_consistent"("internal", smallint, "anyelement", integer, "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_compare_prefix_anyenum"("anyenum", "anyenum", smallint, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_anyenum"("anyenum", "anyenum", smallint, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_anyenum"("anyenum", "anyenum", smallint, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_anyenum"("anyenum", "anyenum", smallint, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_compare_prefix_bit"(bit, bit, smallint, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_bit"(bit, bit, smallint, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_bit"(bit, bit, smallint, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_bit"(bit, bit, smallint, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_compare_prefix_bool"(boolean, boolean, smallint, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_bool"(boolean, boolean, smallint, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_bool"(boolean, boolean, smallint, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_bool"(boolean, boolean, smallint, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_compare_prefix_bpchar"(character, character, smallint, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_bpchar"(character, character, smallint, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_bpchar"(character, character, smallint, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_bpchar"(character, character, smallint, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_compare_prefix_bytea"("bytea", "bytea", smallint, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_bytea"("bytea", "bytea", smallint, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_bytea"("bytea", "bytea", smallint, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_bytea"("bytea", "bytea", smallint, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_compare_prefix_char"("char", "char", smallint, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_char"("char", "char", smallint, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_char"("char", "char", smallint, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_char"("char", "char", smallint, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_compare_prefix_cidr"("cidr", "cidr", smallint, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_cidr"("cidr", "cidr", smallint, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_cidr"("cidr", "cidr", smallint, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_cidr"("cidr", "cidr", smallint, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_compare_prefix_date"("date", "date", smallint, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_date"("date", "date", smallint, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_date"("date", "date", smallint, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_date"("date", "date", smallint, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_compare_prefix_float4"(real, real, smallint, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_float4"(real, real, smallint, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_float4"(real, real, smallint, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_float4"(real, real, smallint, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_compare_prefix_float8"(double precision, double precision, smallint, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_float8"(double precision, double precision, smallint, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_float8"(double precision, double precision, smallint, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_float8"(double precision, double precision, smallint, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_compare_prefix_inet"("inet", "inet", smallint, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_inet"("inet", "inet", smallint, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_inet"("inet", "inet", smallint, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_inet"("inet", "inet", smallint, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_compare_prefix_int2"(smallint, smallint, smallint, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_int2"(smallint, smallint, smallint, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_int2"(smallint, smallint, smallint, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_int2"(smallint, smallint, smallint, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_compare_prefix_int4"(integer, integer, smallint, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_int4"(integer, integer, smallint, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_int4"(integer, integer, smallint, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_int4"(integer, integer, smallint, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_compare_prefix_int8"(bigint, bigint, smallint, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_int8"(bigint, bigint, smallint, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_int8"(bigint, bigint, smallint, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_int8"(bigint, bigint, smallint, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_compare_prefix_interval"(interval, interval, smallint, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_interval"(interval, interval, smallint, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_interval"(interval, interval, smallint, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_interval"(interval, interval, smallint, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_compare_prefix_macaddr"("macaddr", "macaddr", smallint, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_macaddr"("macaddr", "macaddr", smallint, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_macaddr"("macaddr", "macaddr", smallint, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_macaddr"("macaddr", "macaddr", smallint, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_compare_prefix_macaddr8"("macaddr8", "macaddr8", smallint, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_macaddr8"("macaddr8", "macaddr8", smallint, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_macaddr8"("macaddr8", "macaddr8", smallint, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_macaddr8"("macaddr8", "macaddr8", smallint, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_compare_prefix_money"("money", "money", smallint, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_money"("money", "money", smallint, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_money"("money", "money", smallint, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_money"("money", "money", smallint, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_compare_prefix_name"("name", "name", smallint, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_name"("name", "name", smallint, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_name"("name", "name", smallint, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_name"("name", "name", smallint, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_compare_prefix_numeric"(numeric, numeric, smallint, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_numeric"(numeric, numeric, smallint, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_numeric"(numeric, numeric, smallint, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_numeric"(numeric, numeric, smallint, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_compare_prefix_oid"("oid", "oid", smallint, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_oid"("oid", "oid", smallint, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_oid"("oid", "oid", smallint, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_oid"("oid", "oid", smallint, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_compare_prefix_text"("text", "text", smallint, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_text"("text", "text", smallint, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_text"("text", "text", smallint, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_text"("text", "text", smallint, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_compare_prefix_time"(time without time zone, time without time zone, smallint, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_time"(time without time zone, time without time zone, smallint, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_time"(time without time zone, time without time zone, smallint, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_time"(time without time zone, time without time zone, smallint, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_compare_prefix_timestamp"(timestamp without time zone, timestamp without time zone, smallint, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_timestamp"(timestamp without time zone, timestamp without time zone, smallint, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_timestamp"(timestamp without time zone, timestamp without time zone, smallint, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_timestamp"(timestamp without time zone, timestamp without time zone, smallint, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_compare_prefix_timestamptz"(timestamp with time zone, timestamp with time zone, smallint, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_timestamptz"(timestamp with time zone, timestamp with time zone, smallint, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_timestamptz"(timestamp with time zone, timestamp with time zone, smallint, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_timestamptz"(timestamp with time zone, timestamp with time zone, smallint, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_compare_prefix_timetz"(time with time zone, time with time zone, smallint, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_timetz"(time with time zone, time with time zone, smallint, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_timetz"(time with time zone, time with time zone, smallint, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_timetz"(time with time zone, time with time zone, smallint, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_compare_prefix_uuid"("uuid", "uuid", smallint, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_uuid"("uuid", "uuid", smallint, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_uuid"("uuid", "uuid", smallint, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_uuid"("uuid", "uuid", smallint, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_compare_prefix_varbit"(bit varying, bit varying, smallint, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_varbit"(bit varying, bit varying, smallint, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_varbit"(bit varying, bit varying, smallint, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_compare_prefix_varbit"(bit varying, bit varying, smallint, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_enum_cmp"("anyenum", "anyenum") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_enum_cmp"("anyenum", "anyenum") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_enum_cmp"("anyenum", "anyenum") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_enum_cmp"("anyenum", "anyenum") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_query_anyenum"("anyenum", "internal", smallint, "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_query_anyenum"("anyenum", "internal", smallint, "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_query_anyenum"("anyenum", "internal", smallint, "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_query_anyenum"("anyenum", "internal", smallint, "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_query_bit"(bit, "internal", smallint, "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_query_bit"(bit, "internal", smallint, "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_query_bit"(bit, "internal", smallint, "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_query_bit"(bit, "internal", smallint, "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_query_bool"(boolean, "internal", smallint, "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_query_bool"(boolean, "internal", smallint, "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_query_bool"(boolean, "internal", smallint, "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_query_bool"(boolean, "internal", smallint, "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_query_bpchar"(character, "internal", smallint, "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_query_bpchar"(character, "internal", smallint, "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_query_bpchar"(character, "internal", smallint, "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_query_bpchar"(character, "internal", smallint, "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_query_bytea"("bytea", "internal", smallint, "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_query_bytea"("bytea", "internal", smallint, "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_query_bytea"("bytea", "internal", smallint, "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_query_bytea"("bytea", "internal", smallint, "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_query_char"("char", "internal", smallint, "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_query_char"("char", "internal", smallint, "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_query_char"("char", "internal", smallint, "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_query_char"("char", "internal", smallint, "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_query_cidr"("cidr", "internal", smallint, "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_query_cidr"("cidr", "internal", smallint, "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_query_cidr"("cidr", "internal", smallint, "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_query_cidr"("cidr", "internal", smallint, "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_query_date"("date", "internal", smallint, "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_query_date"("date", "internal", smallint, "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_query_date"("date", "internal", smallint, "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_query_date"("date", "internal", smallint, "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_query_float4"(real, "internal", smallint, "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_query_float4"(real, "internal", smallint, "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_query_float4"(real, "internal", smallint, "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_query_float4"(real, "internal", smallint, "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_query_float8"(double precision, "internal", smallint, "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_query_float8"(double precision, "internal", smallint, "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_query_float8"(double precision, "internal", smallint, "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_query_float8"(double precision, "internal", smallint, "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_query_inet"("inet", "internal", smallint, "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_query_inet"("inet", "internal", smallint, "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_query_inet"("inet", "internal", smallint, "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_query_inet"("inet", "internal", smallint, "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_query_int2"(smallint, "internal", smallint, "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_query_int2"(smallint, "internal", smallint, "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_query_int2"(smallint, "internal", smallint, "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_query_int2"(smallint, "internal", smallint, "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_query_int4"(integer, "internal", smallint, "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_query_int4"(integer, "internal", smallint, "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_query_int4"(integer, "internal", smallint, "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_query_int4"(integer, "internal", smallint, "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_query_int8"(bigint, "internal", smallint, "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_query_int8"(bigint, "internal", smallint, "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_query_int8"(bigint, "internal", smallint, "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_query_int8"(bigint, "internal", smallint, "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_query_interval"(interval, "internal", smallint, "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_query_interval"(interval, "internal", smallint, "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_query_interval"(interval, "internal", smallint, "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_query_interval"(interval, "internal", smallint, "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_query_macaddr"("macaddr", "internal", smallint, "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_query_macaddr"("macaddr", "internal", smallint, "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_query_macaddr"("macaddr", "internal", smallint, "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_query_macaddr"("macaddr", "internal", smallint, "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_query_macaddr8"("macaddr8", "internal", smallint, "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_query_macaddr8"("macaddr8", "internal", smallint, "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_query_macaddr8"("macaddr8", "internal", smallint, "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_query_macaddr8"("macaddr8", "internal", smallint, "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_query_money"("money", "internal", smallint, "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_query_money"("money", "internal", smallint, "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_query_money"("money", "internal", smallint, "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_query_money"("money", "internal", smallint, "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_query_name"("name", "internal", smallint, "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_query_name"("name", "internal", smallint, "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_query_name"("name", "internal", smallint, "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_query_name"("name", "internal", smallint, "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_query_numeric"(numeric, "internal", smallint, "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_query_numeric"(numeric, "internal", smallint, "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_query_numeric"(numeric, "internal", smallint, "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_query_numeric"(numeric, "internal", smallint, "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_query_oid"("oid", "internal", smallint, "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_query_oid"("oid", "internal", smallint, "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_query_oid"("oid", "internal", smallint, "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_query_oid"("oid", "internal", smallint, "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_query_text"("text", "internal", smallint, "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_query_text"("text", "internal", smallint, "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_query_text"("text", "internal", smallint, "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_query_text"("text", "internal", smallint, "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_query_time"(time without time zone, "internal", smallint, "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_query_time"(time without time zone, "internal", smallint, "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_query_time"(time without time zone, "internal", smallint, "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_query_time"(time without time zone, "internal", smallint, "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_query_timestamp"(timestamp without time zone, "internal", smallint, "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_query_timestamp"(timestamp without time zone, "internal", smallint, "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_query_timestamp"(timestamp without time zone, "internal", smallint, "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_query_timestamp"(timestamp without time zone, "internal", smallint, "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_query_timestamptz"(timestamp with time zone, "internal", smallint, "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_query_timestamptz"(timestamp with time zone, "internal", smallint, "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_query_timestamptz"(timestamp with time zone, "internal", smallint, "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_query_timestamptz"(timestamp with time zone, "internal", smallint, "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_query_timetz"(time with time zone, "internal", smallint, "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_query_timetz"(time with time zone, "internal", smallint, "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_query_timetz"(time with time zone, "internal", smallint, "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_query_timetz"(time with time zone, "internal", smallint, "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_query_trgm"("text", "internal", smallint, "internal", "internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_query_trgm"("text", "internal", smallint, "internal", "internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_query_trgm"("text", "internal", smallint, "internal", "internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_query_trgm"("text", "internal", smallint, "internal", "internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_query_uuid"("uuid", "internal", smallint, "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_query_uuid"("uuid", "internal", smallint, "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_query_uuid"("uuid", "internal", smallint, "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_query_uuid"("uuid", "internal", smallint, "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_query_varbit"(bit varying, "internal", smallint, "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_query_varbit"(bit varying, "internal", smallint, "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_query_varbit"(bit varying, "internal", smallint, "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_query_varbit"(bit varying, "internal", smallint, "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_value_anyenum"("anyenum", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_value_anyenum"("anyenum", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_value_anyenum"("anyenum", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_value_anyenum"("anyenum", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_value_bit"(bit, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_value_bit"(bit, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_value_bit"(bit, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_value_bit"(bit, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_value_bool"(boolean, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_value_bool"(boolean, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_value_bool"(boolean, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_value_bool"(boolean, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_value_bpchar"(character, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_value_bpchar"(character, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_value_bpchar"(character, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_value_bpchar"(character, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_value_bytea"("bytea", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_value_bytea"("bytea", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_value_bytea"("bytea", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_value_bytea"("bytea", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_value_char"("char", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_value_char"("char", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_value_char"("char", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_value_char"("char", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_value_cidr"("cidr", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_value_cidr"("cidr", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_value_cidr"("cidr", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_value_cidr"("cidr", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_value_date"("date", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_value_date"("date", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_value_date"("date", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_value_date"("date", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_value_float4"(real, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_value_float4"(real, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_value_float4"(real, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_value_float4"(real, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_value_float8"(double precision, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_value_float8"(double precision, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_value_float8"(double precision, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_value_float8"(double precision, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_value_inet"("inet", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_value_inet"("inet", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_value_inet"("inet", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_value_inet"("inet", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_value_int2"(smallint, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_value_int2"(smallint, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_value_int2"(smallint, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_value_int2"(smallint, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_value_int4"(integer, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_value_int4"(integer, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_value_int4"(integer, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_value_int4"(integer, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_value_int8"(bigint, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_value_int8"(bigint, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_value_int8"(bigint, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_value_int8"(bigint, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_value_interval"(interval, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_value_interval"(interval, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_value_interval"(interval, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_value_interval"(interval, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_value_macaddr"("macaddr", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_value_macaddr"("macaddr", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_value_macaddr"("macaddr", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_value_macaddr"("macaddr", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_value_macaddr8"("macaddr8", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_value_macaddr8"("macaddr8", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_value_macaddr8"("macaddr8", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_value_macaddr8"("macaddr8", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_value_money"("money", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_value_money"("money", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_value_money"("money", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_value_money"("money", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_value_name"("name", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_value_name"("name", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_value_name"("name", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_value_name"("name", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_value_numeric"(numeric, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_value_numeric"(numeric, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_value_numeric"(numeric, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_value_numeric"(numeric, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_value_oid"("oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_value_oid"("oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_value_oid"("oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_value_oid"("oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_value_text"("text", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_value_text"("text", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_value_text"("text", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_value_text"("text", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_value_time"(time without time zone, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_value_time"(time without time zone, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_value_time"(time without time zone, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_value_time"(time without time zone, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_value_timestamp"(timestamp without time zone, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_value_timestamp"(timestamp without time zone, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_value_timestamp"(timestamp without time zone, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_value_timestamp"(timestamp without time zone, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_value_timestamptz"(timestamp with time zone, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_value_timestamptz"(timestamp with time zone, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_value_timestamptz"(timestamp with time zone, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_value_timestamptz"(timestamp with time zone, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_value_timetz"(time with time zone, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_value_timetz"(time with time zone, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_value_timetz"(time with time zone, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_value_timetz"(time with time zone, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_value_trgm"("text", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_value_trgm"("text", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_value_trgm"("text", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_value_trgm"("text", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_value_uuid"("uuid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_value_uuid"("uuid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_value_uuid"("uuid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_value_uuid"("uuid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_value_varbit"(bit varying, "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_value_varbit"(bit varying, "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_value_varbit"(bit varying, "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_value_varbit"(bit varying, "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_numeric_cmp"(numeric, numeric) TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_numeric_cmp"(numeric, numeric) TO "anon";
GRANT ALL ON FUNCTION "public"."gin_numeric_cmp"(numeric, numeric) TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_numeric_cmp"(numeric, numeric) TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_trgm_consistent"("internal", smallint, "text", integer, "internal", "internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_trgm_consistent"("internal", smallint, "text", integer, "internal", "internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_trgm_consistent"("internal", smallint, "text", integer, "internal", "internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_trgm_consistent"("internal", smallint, "text", integer, "internal", "internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_trgm_triconsistent"("internal", smallint, "text", integer, "internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_trgm_triconsistent"("internal", smallint, "text", integer, "internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_trgm_triconsistent"("internal", smallint, "text", integer, "internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_trgm_triconsistent"("internal", smallint, "text", integer, "internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_compress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_compress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_compress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_compress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_consistent"("internal", "text", smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_consistent"("internal", "text", smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_consistent"("internal", "text", smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_consistent"("internal", "text", smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_decompress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_decompress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_decompress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_decompress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_distance"("internal", "text", smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_distance"("internal", "text", smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_distance"("internal", "text", smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_distance"("internal", "text", smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_options"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_options"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_options"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_options"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_penalty"("internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_penalty"("internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_penalty"("internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_penalty"("internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_picksplit"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_picksplit"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_picksplit"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_picksplit"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_same"("public"."gtrgm", "public"."gtrgm", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_same"("public"."gtrgm", "public"."gtrgm", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_same"("public"."gtrgm", "public"."gtrgm", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_same"("public"."gtrgm", "public"."gtrgm", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_union"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_union"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_union"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_union"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."search"("search_term" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."search"("search_term" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."search"("search_term" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."search_organisms"("search_term" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."search_organisms"("search_term" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."search_organisms"("search_term" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."search_taxonomy"("search_term" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."search_taxonomy"("search_term" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."search_taxonomy"("search_term" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."set_limit"(real) TO "postgres";
GRANT ALL ON FUNCTION "public"."set_limit"(real) TO "anon";
GRANT ALL ON FUNCTION "public"."set_limit"(real) TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_limit"(real) TO "service_role";



GRANT ALL ON FUNCTION "public"."show_limit"() TO "postgres";
GRANT ALL ON FUNCTION "public"."show_limit"() TO "anon";
GRANT ALL ON FUNCTION "public"."show_limit"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."show_limit"() TO "service_role";



GRANT ALL ON FUNCTION "public"."show_trgm"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."show_trgm"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."show_trgm"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."show_trgm"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."similarity"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."similarity"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."similarity"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."similarity"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."similarity_dist"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."similarity_dist"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."similarity_dist"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."similarity_dist"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."similarity_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."similarity_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."similarity_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."similarity_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity_commutator_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_commutator_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_commutator_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_commutator_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_commutator_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_commutator_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_commutator_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_commutator_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity_commutator_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity_commutator_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity_commutator_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity_commutator_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity_dist_commutator_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_commutator_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_commutator_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_commutator_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity_dist_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity_op"("text", "text") TO "service_role";



























GRANT ALL ON TABLE "public"."anthropology_catalogue" TO "anon";
GRANT ALL ON TABLE "public"."anthropology_catalogue" TO "authenticated";
GRANT ALL ON TABLE "public"."anthropology_catalogue" TO "service_role";



GRANT ALL ON SEQUENCE "public"."anthropology_catalogue_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."anthropology_catalogue_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."anthropology_catalogue_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."anthropology_cultures" TO "anon";
GRANT ALL ON TABLE "public"."anthropology_cultures" TO "authenticated";
GRANT ALL ON TABLE "public"."anthropology_cultures" TO "service_role";



GRANT ALL ON TABLE "public"."media" TO "anon";
GRANT ALL ON TABLE "public"."media" TO "authenticated";
GRANT ALL ON TABLE "public"."media" TO "service_role";



GRANT ALL ON TABLE "public"."media_catalogue" TO "anon";
GRANT ALL ON TABLE "public"."media_catalogue" TO "authenticated";
GRANT ALL ON TABLE "public"."media_catalogue" TO "service_role";



GRANT ALL ON SEQUENCE "public"."media_catalogue_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."media_catalogue_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."media_catalogue_id_seq" TO "service_role";



GRANT ALL ON SEQUENCE "public"."media_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."media_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."media_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."minerals" TO "anon";
GRANT ALL ON TABLE "public"."minerals" TO "authenticated";
GRANT ALL ON TABLE "public"."minerals" TO "service_role";



GRANT ALL ON TABLE "public"."minerals_catalogue_taxonomy_join" TO "anon";
GRANT ALL ON TABLE "public"."minerals_catalogue_taxonomy_join" TO "authenticated";
GRANT ALL ON TABLE "public"."minerals_catalogue_taxonomy_join" TO "service_role";



GRANT ALL ON SEQUENCE "public"."minerals_catalogue_taxonomy_join_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."minerals_catalogue_taxonomy_join_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."minerals_catalogue_taxonomy_join_id_seq" TO "service_role";



GRANT ALL ON SEQUENCE "public"."minerals_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."minerals_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."minerals_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."minerals_taxonomy" TO "anon";
GRANT ALL ON TABLE "public"."minerals_taxonomy" TO "authenticated";
GRANT ALL ON TABLE "public"."minerals_taxonomy" TO "service_role";



GRANT ALL ON SEQUENCE "public"."minerals_taxonomy_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."minerals_taxonomy_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."minerals_taxonomy_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."organisms" TO "anon";
GRANT ALL ON TABLE "public"."organisms" TO "authenticated";
GRANT ALL ON TABLE "public"."organisms" TO "service_role";



GRANT ALL ON TABLE "public"."taxonomy" TO "anon";
GRANT ALL ON TABLE "public"."taxonomy" TO "authenticated";
GRANT ALL ON TABLE "public"."taxonomy" TO "service_role";



GRANT ALL ON SEQUENCE "public"."taxonomy_irn_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."taxonomy_irn_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."taxonomy_irn_seq" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";





























RESET ALL;
