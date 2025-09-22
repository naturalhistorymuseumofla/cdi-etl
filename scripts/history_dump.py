import pandas as pd

from etl.extractors import xml_to_json
from etl.transformers.history.catalogue import transform_history_catalogue

records = xml_to_json("data/raw-data/history_catalogue.xml")
df = pd.DataFrame(records).fillna("")
df = transform_history_catalogue(df)

print(f"Extracted {len(df)} records from history_catalogue.xml")
