

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


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "moddatetime" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";





SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."anthropology_catalogue" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
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
    "cultural_attribution_verbatim" "text"[],
    "site_summary" "text",
    "site_number" "text",
    "site_name" "text"[],
    "site_irn" bigint,
    "material_type" "jsonb"
);


ALTER TABLE "public"."anthropology_catalogue" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."anthropology_catalogue_cultures_join" (
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "catalogue_irn" bigint NOT NULL,
    "cultures_id" bigint NOT NULL
);


ALTER TABLE "public"."anthropology_catalogue_cultures_join" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."anthropology_catalogue_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."anthropology_catalogue_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."anthropology_catalogue_id_seq" OWNED BY "public"."anthropology_catalogue"."id";



CREATE TABLE IF NOT EXISTS "public"."anthropology_cultures" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
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
    "airtable_id" "text",
    "date_airtable_record_modified" "date"
);


ALTER TABLE "public"."anthropology_cultures" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."anthropology_cultures_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."anthropology_cultures_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."anthropology_cultures_id_seq" OWNED BY "public"."anthropology_cultures"."id";



CREATE TABLE IF NOT EXISTS "public"."biology_catalogue" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "irn" bigint NOT NULL,
    "date_emu_record_modified" "date",
    "date_emu_record_inserted" "date",
    "emu_guid" "uuid",
    "catalogue_number" "text",
    "department" "text",
    "caste" "text",
    "sex" "text",
    "life_stage" "text",
    "side" "text",
    "element" "text",
    "type_status" "text",
    "locality_irn" bigint,
    "locality" "text",
    "taxon_irn" bigint,
    "verbatim_element" "text"
);


ALTER TABLE "public"."biology_catalogue" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."biology_catalogue_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."biology_catalogue_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."biology_catalogue_id_seq" OWNED BY "public"."biology_catalogue"."id";



CREATE TABLE IF NOT EXISTS "public"."biology_taxonomy" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "irn" bigint NOT NULL,
    "date_emu_record_modified" "date",
    "date_emu_record_inserted" "date",
    "department" "text",
    "parent_irn" bigint,
    "scientific_name" "text",
    "taxon_rank" "text",
    "kingdom" "text",
    "phylum" "text",
    "subphylum" "text",
    "superclass" "text",
    "class" "text",
    "subclass" "text",
    "superorder" "text",
    "order" "text",
    "suborder" "text",
    "infraorder" "text",
    "superfamily" "text",
    "family" "text",
    "subfamily" "text",
    "tribe" "text",
    "genus" "text",
    "subgenus" "text",
    "species" "text",
    "subspecies" "text",
    "common_name" "text",
    "current_name_irn" integer
);


ALTER TABLE "public"."biology_taxonomy" OWNER TO "postgres";


COMMENT ON COLUMN "public"."biology_taxonomy"."current_name_irn" IS 'Currently accepted record''s IRN';



CREATE SEQUENCE IF NOT EXISTS "public"."biology_taxonomy_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."biology_taxonomy_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."biology_taxonomy_id_seq" OWNED BY "public"."biology_taxonomy"."id";



CREATE TABLE IF NOT EXISTS "public"."media" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "dams_id" bigint NOT NULL,
    "source" "text",
    "format" "text",
    "creator" "text",
    "license" "text",
    "type" "text",
    "url" "text",
    "title" "text",
    "description" "text",
    "uploaded_datetime" timestamp with time zone,
    "publish_to_collection_page" boolean DEFAULT false,
    "is_authoritative" boolean DEFAULT false
);


ALTER TABLE "public"."media" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."media_catalogue" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "media_id" bigint,
    "irn" bigint NOT NULL,
    "domain" "text"
);


ALTER TABLE "public"."media_catalogue" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."media_catalogue_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."media_catalogue_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."media_catalogue_id_seq" OWNED BY "public"."media_catalogue"."id";



CREATE SEQUENCE IF NOT EXISTS "public"."media_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."media_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."media_id_seq" OWNED BY "public"."media"."id";



CREATE TABLE IF NOT EXISTS "public"."mineralogy_catalogue" (
    "id" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "irn" bigint NOT NULL,
    "date_emu_record_modified" "date",
    "date_emu_record_inserted" "date",
    "catalogue_number" "text",
    "emu_guid" "uuid",
    "category" "text",
    "size" "text",
    "verbatim_size" "text",
    "jewelry_type" "text",
    "description" "text",
    "dimensions" "text",
    "length" double precision,
    "width" double precision,
    "height" double precision,
    "specimens" "jsonb"
);


ALTER TABLE "public"."mineralogy_catalogue" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."mineralogy_catalogue_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."mineralogy_catalogue_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."mineralogy_catalogue_id_seq" OWNED BY "public"."mineralogy_catalogue"."id";



CREATE TABLE IF NOT EXISTS "public"."mineralogy_catalogue_taxonomy" (
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "catalogue_irn" bigint NOT NULL,
    "taxonomy_id" bigint NOT NULL
);


ALTER TABLE "public"."mineralogy_catalogue_taxonomy" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."mineralogy_taxonomy" (
    "id" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "irn" bigint NOT NULL,
    "date_emu_record_modified" "date",
    "date_emu_record_inserted" "date",
    "species" "text",
    "group" "text",
    "formula" "text",
    "is_valid" boolean,
    "mindat_id" integer,
    "mindat_name" "text",
    "mindat_group_id" integer,
    "mindat_ima_status" "text"[],
    "mindat_ima_notes" "text",
    "mindat_elements" "text"[],
    "mindat_formula" "text",
    "mindat_variety_of" integer,
    "mindat_syn_id" integer,
    "mindat_entry_type" "text",
    "mindat_description" "text",
    "mindat_tenacity" "text",
    "mindat_strunz_1" integer,
    "mindat_strunz_2" "text",
    "mindat_strunz_3" "text",
    "mindat_strunz_4" "text",
    "mindat_rock_parent" integer,
    "mindat_rock_grandparent" integer
);


ALTER TABLE "public"."mineralogy_taxonomy" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."mineralogy_taxonomy_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."mineralogy_taxonomy_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."mineralogy_taxonomy_id_seq" OWNED BY "public"."mineralogy_taxonomy"."id";



ALTER TABLE ONLY "public"."anthropology_catalogue" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."anthropology_catalogue_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."anthropology_cultures" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."anthropology_cultures_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."biology_catalogue" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."biology_catalogue_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."biology_taxonomy" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."biology_taxonomy_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."media" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."media_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."media_catalogue" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."media_catalogue_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."mineralogy_catalogue" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."mineralogy_catalogue_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."mineralogy_taxonomy" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."mineralogy_taxonomy_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."anthropology_catalogue_cultures_join"
    ADD CONSTRAINT "anthropology_catalogue_cultures_join_pkey" PRIMARY KEY ("catalogue_irn", "cultures_id");



ALTER TABLE ONLY "public"."anthropology_catalogue"
    ADD CONSTRAINT "anthropology_catalogue_irn_key" UNIQUE ("irn");



ALTER TABLE ONLY "public"."anthropology_catalogue"
    ADD CONSTRAINT "anthropology_catalogue_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."anthropology_cultures"
    ADD CONSTRAINT "anthropology_cultures_airtable_id_key" UNIQUE ("airtable_id");



ALTER TABLE ONLY "public"."anthropology_cultures"
    ADD CONSTRAINT "anthropology_cultures_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."biology_catalogue"
    ADD CONSTRAINT "biology_catalogue_irn_key" UNIQUE ("irn");



ALTER TABLE ONLY "public"."biology_catalogue"
    ADD CONSTRAINT "biology_catalogue_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."biology_taxonomy"
    ADD CONSTRAINT "biology_taxonomy_irn_key" UNIQUE ("irn");



ALTER TABLE ONLY "public"."biology_taxonomy"
    ADD CONSTRAINT "biology_taxonomy_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."media_catalogue"
    ADD CONSTRAINT "media_catalogue_irn_key" UNIQUE ("irn");



ALTER TABLE ONLY "public"."media_catalogue"
    ADD CONSTRAINT "media_catalogue_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."media"
    ADD CONSTRAINT "media_dams_id_key" UNIQUE ("dams_id");



ALTER TABLE ONLY "public"."media"
    ADD CONSTRAINT "media_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."mineralogy_catalogue"
    ADD CONSTRAINT "mineralogy_catalogue_irn_key" UNIQUE ("irn");



ALTER TABLE ONLY "public"."mineralogy_catalogue"
    ADD CONSTRAINT "mineralogy_catalogue_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."mineralogy_catalogue_taxonomy"
    ADD CONSTRAINT "mineralogy_catalogue_taxonomy_pkey" PRIMARY KEY ("catalogue_irn", "taxonomy_id");



ALTER TABLE ONLY "public"."mineralogy_taxonomy"
    ADD CONSTRAINT "mineralogy_taxonomy_irn_key" UNIQUE ("irn");



ALTER TABLE ONLY "public"."mineralogy_taxonomy"
    ADD CONSTRAINT "mineralogy_taxonomy_pkey" PRIMARY KEY ("id");



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "public"."anthropology_catalogue" FOR EACH ROW EXECUTE FUNCTION "extensions"."moddatetime"('updated_at');



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "public"."anthropology_catalogue_cultures_join" FOR EACH ROW EXECUTE FUNCTION "extensions"."moddatetime"('updated_at');



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "public"."anthropology_cultures" FOR EACH ROW EXECUTE FUNCTION "extensions"."moddatetime"('updated_at');



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "public"."biology_catalogue" FOR EACH ROW EXECUTE FUNCTION "extensions"."moddatetime"('updated_at');



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "public"."biology_taxonomy" FOR EACH ROW EXECUTE FUNCTION "extensions"."moddatetime"('updated_at');



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "public"."media" FOR EACH ROW EXECUTE FUNCTION "extensions"."moddatetime"('updated_at');



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "public"."media_catalogue" FOR EACH ROW EXECUTE FUNCTION "extensions"."moddatetime"('updated_at');



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "public"."mineralogy_catalogue" FOR EACH ROW EXECUTE FUNCTION "extensions"."moddatetime"('updated_at');



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "public"."mineralogy_taxonomy" FOR EACH ROW EXECUTE FUNCTION "extensions"."moddatetime"('updated_at');



ALTER TABLE ONLY "public"."anthropology_catalogue_cultures_join"
    ADD CONSTRAINT "anthropology_catalogue_cultures_join_catalogue_irn_fkey" FOREIGN KEY ("catalogue_irn") REFERENCES "public"."anthropology_catalogue"("irn");



ALTER TABLE ONLY "public"."anthropology_catalogue_cultures_join"
    ADD CONSTRAINT "anthropology_catalogue_cultures_join_cultures_id_fkey" FOREIGN KEY ("cultures_id") REFERENCES "public"."anthropology_cultures"("id");



ALTER TABLE ONLY "public"."biology_catalogue"
    ADD CONSTRAINT "fk_biology_catalogue_taxon_irn" FOREIGN KEY ("taxon_irn") REFERENCES "public"."biology_taxonomy"("irn") ON UPDATE CASCADE ON DELETE SET NULL;



ALTER TABLE ONLY "public"."media_catalogue"
    ADD CONSTRAINT "media_catalogue_media_id_fkey" FOREIGN KEY ("media_id") REFERENCES "public"."media"("id");



ALTER TABLE ONLY "public"."mineralogy_catalogue_taxonomy"
    ADD CONSTRAINT "mineralogy_catalogue_taxonomy_catalogue_irn_fkey" FOREIGN KEY ("catalogue_irn") REFERENCES "public"."mineralogy_catalogue"("irn");



ALTER TABLE ONLY "public"."mineralogy_catalogue_taxonomy"
    ADD CONSTRAINT "mineralogy_catalogue_taxonomy_taxonomy_id_fkey" FOREIGN KEY ("taxonomy_id") REFERENCES "public"."mineralogy_taxonomy"("id");



ALTER TABLE "public"."anthropology_catalogue_cultures_join" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."anthropology_cultures" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."biology_catalogue" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."biology_taxonomy" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."media" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."media_catalogue" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."mineralogy_catalogue" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."mineralogy_taxonomy" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";











































































































































































GRANT ALL ON TABLE "public"."anthropology_catalogue" TO "anon";
GRANT ALL ON TABLE "public"."anthropology_catalogue" TO "authenticated";
GRANT ALL ON TABLE "public"."anthropology_catalogue" TO "service_role";



GRANT ALL ON TABLE "public"."anthropology_catalogue_cultures_join" TO "anon";
GRANT ALL ON TABLE "public"."anthropology_catalogue_cultures_join" TO "authenticated";
GRANT ALL ON TABLE "public"."anthropology_catalogue_cultures_join" TO "service_role";



GRANT ALL ON SEQUENCE "public"."anthropology_catalogue_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."anthropology_catalogue_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."anthropology_catalogue_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."anthropology_cultures" TO "anon";
GRANT ALL ON TABLE "public"."anthropology_cultures" TO "authenticated";
GRANT ALL ON TABLE "public"."anthropology_cultures" TO "service_role";



GRANT ALL ON SEQUENCE "public"."anthropology_cultures_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."anthropology_cultures_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."anthropology_cultures_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."biology_catalogue" TO "anon";
GRANT ALL ON TABLE "public"."biology_catalogue" TO "authenticated";
GRANT ALL ON TABLE "public"."biology_catalogue" TO "service_role";



GRANT ALL ON SEQUENCE "public"."biology_catalogue_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."biology_catalogue_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."biology_catalogue_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."biology_taxonomy" TO "anon";
GRANT ALL ON TABLE "public"."biology_taxonomy" TO "authenticated";
GRANT ALL ON TABLE "public"."biology_taxonomy" TO "service_role";



GRANT ALL ON SEQUENCE "public"."biology_taxonomy_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."biology_taxonomy_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."biology_taxonomy_id_seq" TO "service_role";



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



GRANT ALL ON TABLE "public"."mineralogy_catalogue" TO "anon";
GRANT ALL ON TABLE "public"."mineralogy_catalogue" TO "authenticated";
GRANT ALL ON TABLE "public"."mineralogy_catalogue" TO "service_role";



GRANT ALL ON SEQUENCE "public"."mineralogy_catalogue_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."mineralogy_catalogue_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."mineralogy_catalogue_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."mineralogy_catalogue_taxonomy" TO "anon";
GRANT ALL ON TABLE "public"."mineralogy_catalogue_taxonomy" TO "authenticated";
GRANT ALL ON TABLE "public"."mineralogy_catalogue_taxonomy" TO "service_role";



GRANT ALL ON TABLE "public"."mineralogy_taxonomy" TO "anon";
GRANT ALL ON TABLE "public"."mineralogy_taxonomy" TO "authenticated";
GRANT ALL ON TABLE "public"."mineralogy_taxonomy" TO "service_role";



GRANT ALL ON SEQUENCE "public"."mineralogy_taxonomy_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."mineralogy_taxonomy_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."mineralogy_taxonomy_id_seq" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";






























