import pandas as pd

from etl.extractors import xml_to_json
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
    catalogue_df.to_csv("data/anthro_catalogue_transformed.csv", index=False)
    join_df.to_csv("data/anthro_catalogues_cultures_join.csv", index=False)
    cultures_df.to_csv("data/cultures.csv", index=False)

    print("Wrote files:")
    print(" - data/anthro_catalogue_transformed.csv")
    print(" - data/anthro_catalogues_cultures_join.csv")
    print(" - data/cultures.csv")
