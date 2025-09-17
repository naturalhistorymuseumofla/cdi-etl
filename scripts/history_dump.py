import pandas as pd

from etl.extractors import xml_to_json

records = xml_to_json("data/raw-data/history_catalogue.xml")
df = pd.DataFrame(records).fillna("")

print(f"Extracted {len(df)} records from history_catalogue.xml")
