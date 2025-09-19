create extension if not exists "moddatetime" with schema "extensions";


alter table "public"."anthropology_catalogue" add column "updated_at" timestamp without time zone;

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.anthropology_catalogue FOR EACH ROW EXECUTE FUNCTION moddatetime('updated_at');


