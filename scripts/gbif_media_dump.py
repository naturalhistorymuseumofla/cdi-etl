"""
Script to dump GBIF media into media table. These media are linked to biology_catalogue records.
This script is intended as a proof of concept for media in the CDI. Future iterations will use
records from Censhare.

This script requires a GBIF media dump CSV file path to be set in the environment variable
PATH_TO_GBIF_MEDIA_DUMP.

It also requires a csv of biology_catalogue records with GBIF IDs to link the media to.
"""

from config.settings import settings
import pandas as pd
from etl.loaders.supabase_loader import SupabaseLoader
from datetime import datetime


if __name__ == "__main__":
    multimedia_dump_path = settings.path_to_gbif_dumps

    # Read CSV dump of GBIF multimedia
    if not multimedia_dump_path:
        raise ValueError("PATH_TO_GBIF_DUMPS is not set in the environment variables.")

    gbif_multimedia = pd.read_csv(
        multimedia_dump_path + "/multimedia.csv",
        usecols={
            "gbifID": int,
            "format": str,
            "identifier": str,
            "title": str,
            "description": str,
            "source": str,
            "license": str,
            "creator": str,
        },
    )

    # Read biology_catalogue records to link media
    biology_catalogue_path = settings.path_to_supabase_biology_catalogue
    if not biology_catalogue_path:
        raise ValueError(
            "PATH_TO_SUPABASE_BIOLOGY_CATALOGUE is not set in the environment variables."
        )
    biology_catalogue = pd.read_csv(
        biology_catalogue_path,
        usecols={"irn": int, "gbif_id": int},
    )

    # Clean URL
    gbif_multimedia["identifier"] = gbif_multimedia["identifier"].str.replace(
        "/preview", ""
    )
    # Construct dams_id from identifier URL
    gbif_multimedia["dams_id"] = (
        gbif_multimedia["identifier"].str.split("/").str[-1].astype(int)
    )

    # Merge multimedia with biology_catalogue on gbifID
    media = pd.merge(
        gbif_multimedia,
        biology_catalogue,
        left_on="gbifID",
        right_on="gbif_id",
        how="inner",
    )

    # Prepare media dataframe for loading
    media.drop(columns=["gbifID", "gbif_id"], inplace=True)
    media["source"] = "extensis"
    media["uploaded_on"] = None
    media["updated_at"] = datetime.now().isoformat()
    media["publish_to_collection_pages"] = True
    media["museum_function"] = "collections"
    media["asset_type"] = "image"
    media.rename(columns={"format": "mimetype", "identifier": "url"}, inplace=True)

    # Prepare media_catalogue dataframe for loading
    media_catalogue = media[["irn", "dams_id"]].copy()
    media.drop(columns=["irn"], inplace=True)

    # Load media and link to biology_catalogue
    loader = SupabaseLoader()

    results = loader.load_dataframe(
        "media",
        media,
        upsert=True,
        primary_key="dams_id",
    )

    # Prepare media_catalogue join table
    media_records = pd.DataFrame(results[0])
    media_records = media_records[["dams_id", "id"]]
    media_records.rename(columns={"id": "media_id"}, inplace=True)

    media_catalogue = pd.merge(
        media_catalogue,
        media_records,
        left_on="dams_id",
        right_on="dams_id",
        how="inner",
    )

    # Finalize media_catalogue dataframe for loading
    media_catalogue["domain"] = "biology_catalogue"
    media_catalogue.drop(columns=["dams_id"], inplace=True)
    media_catalogue = media_catalogue.reset_index().rename(columns={"index": "id"})
    media_catalogue["id"] = media_catalogue["id"] + 1

    loader.sync_join_table(
        "media_catalogue",
        media_catalogue,
        source_key="irn",
        target_key="media_id",
    )

    print(f"Loaded {len(media)} media records and linked to biology_catalogue records.")
