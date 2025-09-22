create sequence "public"."anthropology_cultures_id_seq";

create table "public"."anthropology_catalogue_cultures_join" (
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "catalogue_irn" bigint not null,
    "cultures_id" bigint not null
);


alter table "public"."anthropology_catalogue_cultures_join" enable row level security;

alter table "public"."anthropology_catalogue" drop column "cultural_attribution";

alter table "public"."anthropology_catalogue" add column "cultural_attribution_verbatim" text[];

alter table "public"."anthropology_catalogue" alter column "site_name" set data type text[] using "site_name"::text[];

alter table "public"."anthropology_catalogue" alter column "updated_at" set default now();

alter table "public"."anthropology_catalogue" alter column "updated_at" set data type timestamp with time zone using "updated_at"::timestamp with time zone;

alter table "public"."anthropology_catalogue" disable row level security;

alter table "public"."anthropology_cultures" add column "created_at" timestamp with time zone default now();

alter table "public"."anthropology_cultures" add column "date_airtable_record_modified" date;

alter table "public"."anthropology_cultures" add column "updated_at" timestamp with time zone default now();

alter table "public"."anthropology_cultures" alter column "id" set default nextval('anthropology_cultures_id_seq'::regclass);

alter sequence "public"."anthropology_cultures_id_seq" owned by "public"."anthropology_cultures"."id";

CREATE UNIQUE INDEX anthropology_catalogue_cultures_join_pkey ON public.anthropology_catalogue_cultures_join USING btree (catalogue_irn, cultures_id);

alter table "public"."anthropology_catalogue_cultures_join" add constraint "anthropology_catalogue_cultures_join_pkey" PRIMARY KEY using index "anthropology_catalogue_cultures_join_pkey";

alter table "public"."anthropology_catalogue_cultures_join" add constraint "anthropology_catalogue_cultures_join_catalogue_irn_fkey" FOREIGN KEY (catalogue_irn) REFERENCES anthropology_catalogue(irn) not valid;

alter table "public"."anthropology_catalogue_cultures_join" validate constraint "anthropology_catalogue_cultures_join_catalogue_irn_fkey";

alter table "public"."anthropology_catalogue_cultures_join" add constraint "anthropology_catalogue_cultures_join_cultures_id_fkey" FOREIGN KEY (cultures_id) REFERENCES anthropology_cultures(id) not valid;

alter table "public"."anthropology_catalogue_cultures_join" validate constraint "anthropology_catalogue_cultures_join_cultures_id_fkey";

grant delete on table "public"."anthropology_catalogue_cultures_join" to "anon";

grant insert on table "public"."anthropology_catalogue_cultures_join" to "anon";

grant references on table "public"."anthropology_catalogue_cultures_join" to "anon";

grant select on table "public"."anthropology_catalogue_cultures_join" to "anon";

grant trigger on table "public"."anthropology_catalogue_cultures_join" to "anon";

grant truncate on table "public"."anthropology_catalogue_cultures_join" to "anon";

grant update on table "public"."anthropology_catalogue_cultures_join" to "anon";

grant delete on table "public"."anthropology_catalogue_cultures_join" to "authenticated";

grant insert on table "public"."anthropology_catalogue_cultures_join" to "authenticated";

grant references on table "public"."anthropology_catalogue_cultures_join" to "authenticated";

grant select on table "public"."anthropology_catalogue_cultures_join" to "authenticated";

grant trigger on table "public"."anthropology_catalogue_cultures_join" to "authenticated";

grant truncate on table "public"."anthropology_catalogue_cultures_join" to "authenticated";

grant update on table "public"."anthropology_catalogue_cultures_join" to "authenticated";

grant delete on table "public"."anthropology_catalogue_cultures_join" to "service_role";

grant insert on table "public"."anthropology_catalogue_cultures_join" to "service_role";

grant references on table "public"."anthropology_catalogue_cultures_join" to "service_role";

grant select on table "public"."anthropology_catalogue_cultures_join" to "service_role";

grant trigger on table "public"."anthropology_catalogue_cultures_join" to "service_role";

grant truncate on table "public"."anthropology_catalogue_cultures_join" to "service_role";

grant update on table "public"."anthropology_catalogue_cultures_join" to "service_role";

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.anthropology_catalogue_cultures_join FOR EACH ROW EXECUTE FUNCTION moddatetime('updated_at');

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.anthropology_cultures FOR EACH ROW EXECUTE FUNCTION moddatetime('updated_at');


