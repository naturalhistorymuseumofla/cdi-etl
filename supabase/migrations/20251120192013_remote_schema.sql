create extension if not exists "moddatetime" with schema "extensions";

create sequence "public"."media_catalogue_id_seq";

create sequence "public"."media_id_seq";

alter table "public"."biology_taxonomy" drop column "catalogue_number";

alter table "public"."biology_taxonomy" drop column "emu_guid";

alter table "public"."biology_taxonomy" drop column "rank";

alter table "public"."biology_taxonomy" add column "current_name_irn" integer;

alter table "public"."biology_taxonomy" add column "taxon_rank" text;

alter table "public"."media" alter column "id" set default nextval('public.media_id_seq'::regclass);

alter table "public"."media_catalogue" alter column "id" set default nextval('public.media_catalogue_id_seq'::regclass);

alter sequence "public"."media_catalogue_id_seq" owned by "public"."media_catalogue"."id";

alter sequence "public"."media_id_seq" owned by "public"."media"."id";

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.anthropology_catalogue FOR EACH ROW EXECUTE FUNCTION extensions.moddatetime('updated_at');

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.anthropology_catalogue_cultures_join FOR EACH ROW EXECUTE FUNCTION extensions.moddatetime('updated_at');

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.anthropology_cultures FOR EACH ROW EXECUTE FUNCTION extensions.moddatetime('updated_at');

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.biology_catalogue FOR EACH ROW EXECUTE FUNCTION extensions.moddatetime('updated_at');

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.biology_taxonomy FOR EACH ROW EXECUTE FUNCTION extensions.moddatetime('updated_at');

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.media FOR EACH ROW EXECUTE FUNCTION extensions.moddatetime('updated_at');

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.media_catalogue FOR EACH ROW EXECUTE FUNCTION extensions.moddatetime('updated_at');

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.mineralogy_catalogue FOR EACH ROW EXECUTE FUNCTION extensions.moddatetime('updated_at');

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.mineralogy_taxonomy FOR EACH ROW EXECUTE FUNCTION extensions.moddatetime('updated_at');


