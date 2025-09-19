import pandas as pd

from etl.extractors import xml_to_json
from etl.loaders.supabase_loader import SupabaseLoader
from etl.transformers.anthropology import Cultures, transform_anthropology_catalogue

if __name__ == "__main__":
    # Extract
    records = xml_to_json("data/raw-data/anthropology_catalogue.xml")
    df = pd.DataFrame(records).fillna("")

    # Transform -> returns (catalogue_df, join_df)
    catalogue_df, join_df = transform_anthropology_catalogue(df)

    # Get cultures df
    cultures_df = Cultures().get_cultures_dataframe()

    # Load
    loader = SupabaseLoader()
    records, operations = loader.load_dataframe(
        "anthropology_catalogue", catalogue_df, upsert=True
    )
    print(f"\nProcessed {len(records)} total records in anthropology_catalogue:")
    print(f" Inserted: {operations['inserted']}")
    print(f" Updated: {operations['updated']}")
