create type "public"."asset_types" as enum ('image', 'video', 'audio', '3d_model', 'captured_dataset', 'project_archive');

create type "public"."mimetypes" as enum ('application', 'audio', 'example', 'font', 'image', 'model', 'text', 'video');

alter table "public"."media" drop column "format";

alter table "public"."media" drop column "type";

alter table "public"."media" drop column "uploaded";

alter table "public"."media" add column "asset_type" public.asset_types;

alter table "public"."media" add column "mimetype" public.mimetypes;

alter table "public"."media" add column "museum_function" text;

alter table "public"."media" add column "uploaded_on" time without time zone;



