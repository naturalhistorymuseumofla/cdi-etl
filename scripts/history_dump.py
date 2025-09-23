import pandas as pd

from etl.extractors import xml_to_json
from etl.loaders.supabase_loader import SupabaseLoader
from etl.transformers.history.catalogue import transform_history_catalogue

records = xml_to_json("data/raw-data/history_catalogue.xml")
df = pd.DataFrame(records).fillna("")
df = transform_history_catalogue(df)

loader = SupabaseLoader()
loader.load_dataframe("history_catalogue", df, upsert=True, primary_key="irn")
