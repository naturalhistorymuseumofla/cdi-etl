alter table "public"."biology_taxonomy" drop column "common_name";

alter table "public"."biology_taxonomy" add column "vernacular_name" text;

alter table "public"."biology_taxonomy" add column "vernacular_name_source" text;



