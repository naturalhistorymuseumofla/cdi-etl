import pandas as pd

from etl.extractors import xml_to_json
from etl.transformers.anthropology import transform_anthropology_catalogue

if __name__ == "__main__":
    # Extract
    records = xml_to_json("data/anthropology_catalogue.xml")
    df = pd.DataFrame(records).fillna("")

    # Transform -> returns (catalogue_df, join_df)
    catalogue_df, join_df = transform_anthropology_catalogue(df)

    # Load
    catalogue_df.to_csv("data/anthro_catalogue_transformed.csv", index=False)
    join_df.to_csv("data/anthro_catalogues_cultures_join.csv", index=False)
