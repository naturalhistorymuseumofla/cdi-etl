import pandas as pd

from etl.extractors import xml_to_json
from etl.loaders.supabase_loader import SupabaseLoader
from etl.transformers.mineralogy.catalogue import transform_mineralogy_catalogue
from etl.transformers.mineralogy.specimens import transform_mineralogy_specimens
from etl.transformers.mineralogy.taxonomy import transform_mineralogy_taxonomy

catalogue_records = xml_to_json("data/raw-data/mineralogy_catalogue.xml")
taxonomy_records = xml_to_json("data/raw-data/mineralogy_taxonomy.xml")

catalogue_df = pd.DataFrame(catalogue_records)

specimens_df = transform_mineralogy_specimens(catalogue_df)
catalogue_df = transform_mineralogy_catalogue(catalogue_df)

taxonomy_df = pd.DataFrame(taxonomy_records)
taxonomy_df = transform_mineralogy_taxonomy(taxonomy_df)

loader = SupabaseLoader()


loader.load_dataframe(
    "mineralogy_taxonomy",
    taxonomy_df,
    upsert=True,
    primary_key="irn",
)

loader.load_dataframe(
    "mineralogy_catalogue",
    catalogue_df,
    upsert=True,
    primary_key="irn",
)

loader.load_dataframe(
    "mineralogy_specimens",
    specimens_df,
    upsert=True,
    primary_key="specimen_id",
)
