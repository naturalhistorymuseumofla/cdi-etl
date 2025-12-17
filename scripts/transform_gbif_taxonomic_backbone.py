"""
Script to transform GBIF taxonomic backbone data for use in the ETL pipeline.
"""

import pandas as pd
from config.settings import settings
from pathlib import Path
import inflect


def clean_vernacular_name(name: str, inflection_engine) -> str:
    """Cleans a vernacular name by stripping whitespace and capitalizing."""
    name = name.strip().capitalize()
    try:
        name = inflection_engine.singular_noun(name) or name
    except Exception:
        pass
    return name


if __name__ == "__main__":
    # Get path to GBIF dumps from settings
    basepath = settings.path_to_gbif_dumps
    if not basepath:
        raise ValueError("PATH_TO_GBIF_DUMPS is not set in the environment variables.")

    basepath = Path(basepath)

    # Validate path
    if not basepath.exists():
        raise ValueError(f"GBIF dumps path does not exist: {basepath}")
    if not basepath.is_dir():
        raise ValueError(f"GBIF dumps path is not a directory: {basepath}")

    # Construct paths to the zipped dump files
    taxon_path = basepath / "Taxon.tsv.zip"
    vern_path = basepath / "VernacularName.tsv.zip"

    if not taxon_path.exists():
        raise FileNotFoundError(f"Taxon file not found: {taxon_path}")
    if not vern_path.exists():
        raise FileNotFoundError(f"VernacularName file not found: {vern_path}")

    # Load GBIF taxonomic backbone dumps
    taxon = pd.read_csv(
        taxon_path,
        sep="\t",
        low_memory=False,
        on_bad_lines="skip",
        compression="zip",
        usecols={
            "taxonID": int,
            "taxonRank": str,
            "canonicalName": str,
        },
    )

    vernacular_names = pd.read_csv(
        vern_path,
        sep="\t",
        low_memory=False,
        on_bad_lines="skip",
        compression="zip",
        usecols={"taxonID": int, "vernacularName": str, "source": str, "language": str},
    )

    # Filter for English vernacular names and language column
    vernacular_names.query("language == 'en'", inplace=True)
    vernacular_names.drop(columns=["language"], inplace=True)

    # Remove vernacular names that are illegal characters
    vernacular_names = vernacular_names[
        ~vernacular_names.vernacularName.str.contains(r"\|")
    ]

    # Clean vernacular names by stripping whitespace and capitalizing
    inflection_engine = inflect.engine()
    vernacular_names["vernacularName"] = vernacular_names["vernacularName"].apply(
        lambda x: clean_vernacular_name(x, inflection_engine)
    )
    # Drop taxon records without canonical names
    taxon.dropna(subset=["canonicalName"], inplace=True)

    # Merge and export to CSV
    merged = pd.merge(vernacular_names, taxon, how="left", on="taxonID")
    merged.to_csv(basepath / "gbif_taxonomic_backbone.csv", index=False)

    print(
        f"Transformed GBIF taxonomic backbone data saved to {basepath}/gbif_taxonomic_backbone.csv"
    )
