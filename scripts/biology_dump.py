from etl import extractors
from etl.loaders.supabase_loader import SupabaseLoader
from etl.transformers.biology.catalogue import transform_biology_catalogue
from etl.transformers.biology.elements import transform_biology_elements
from etl.transformers.biology.taxonomy import transform_biology_taxonomy


catalogue_records = extractors.read_csv("data/biology_catalogue.csv")
elements = extractors.fetch_data_from_airtable("Paleo Elements")
taxonomy = extractors.xml_to_json("data/biology_taxonomy.xml")


taxonomy_df = transform_biology_taxonomy(taxonomy)
catalogue_df, elements_df, elements_join_df = transform_biology_catalogue(
    catalogue_records, taxonomy_df["irn"], elements
)

loader = SupabaseLoader()


records, operations = loader.load_dataframe(
    "biology_taxonomy", taxonomy_df, upsert=True
)
print(f"\nProcessed {len(records)} total records in biology_taxonomy:")
print(f" Inserted: {operations['inserted']}")
print(f" Updated: {operations['updated']}")

records, operations = loader.load_dataframe(
    "biology_catalogue", catalogue_df, upsert=True
)
print(f"\nProcessed {len(records)} total records in biology_catalogue:")
print(f" Inserted: {operations['inserted']}")
print(f" Updated: {operations['updated']}")

records, operations = loader.load_dataframe(
    "biology_elements", elements_df, upsert=True, primary_key="id"
)
print(f"\nProcessed {len(records)} total records in biology_elements:")
print(f" Inserted: {operations['inserted']}")
print(f" Updated: {operations['updated']}")


loader.sync_join_table(
    "biology_catalogue_elements",
    elements_join_df,
    source_key="catalogue_irn",
    target_key="element_id",
)
