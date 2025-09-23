create sequence "public"."history_catalogue_id_seq";

create table "public"."history_catalogue" (
    "id" integer not null default nextval('history_catalogue_id_seq'::regclass),
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

alter sequence "public"."history_catalogue_id_seq" owned by "public"."history_catalogue"."id";

CREATE UNIQUE INDEX history_catalogue_irn_key ON public.history_catalogue USING btree (irn);

CREATE UNIQUE INDEX history_catalogue_pkey ON public.history_catalogue USING btree (id);

alter table "public"."history_catalogue" add constraint "history_catalogue_pkey" PRIMARY KEY using index "history_catalogue_pkey";

alter table "public"."history_catalogue" add constraint "history_catalogue_irn_key" UNIQUE using index "history_catalogue_irn_key";

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

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.history_catalogue FOR EACH ROW EXECUTE FUNCTION moddatetime('updated_at');


