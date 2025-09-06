from etl import extractors
from etl.transformers.biology.catalogue import transform_biology_catalogue

df = extractors.read_csv("data/biology_catalogue.csv")
df = transform_biology_catalogue(df)

df.to_csv("data/biology_catalogue_transformed.csv", index=False)
