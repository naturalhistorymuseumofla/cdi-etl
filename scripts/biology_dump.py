from etl import extractors
from etl.loaders.supabase_loader import SupabaseLoader
from etl.transformers.biology.catalogue import transform_biology_catalogue

df = extractors.read_csv("data/biology_catalogue.csv")
elements = extractors.fetch_data_from_airtable("Paleo Elements")


df = transform_biology_catalogue(df, elements)

loader = SupabaseLoader()
records, operations = loader.load_dataframe("organisms", df, upsert=True)

print(f"\nProcessed {len(records)} total records in organisms:")
print(f" Inserted: {operations['inserted']}")
print(f" Updated: {operations['updated']}")
