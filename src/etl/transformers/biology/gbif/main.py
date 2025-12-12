import pandas as pd
from .matcher import GbifMatcher


def match_gbif_records(
    catalogue_df: pd.DataFrame,
    taxonomy_df: pd.DataFrame,
    vernaculars_matcher: GbifMatcher,
):
    # Add vernacular names to taxonomy and gbif id to catalogue
    gbif_ids = []

    vernaculars = {}

    for guid, taxon_irn in zip(
        catalogue_df["emu_guid"],
        catalogue_df["taxon_irn"],
    ):
        match = vernaculars_matcher.match(guid)
        if match:
            gbif_ids.append(int(match["gbif_id"]))
            vernaculars[taxon_irn] = {
                "vernacular_name": match["vernacular_name"],
                "source": match["source"],
            }
        if not match:
            gbif_ids.append(None)

    # Prepare new vernacular names and sources
    vernaculars_names = []
    sources = []

    for irn, name, src in zip(
        taxonomy_df["irn"],
        taxonomy_df["vernacular_name"],
        taxonomy_df["vernacular_name_source"],
    ):
        if irn in vernaculars:
            vernaculars_names.append(vernaculars[irn]["vernacular_name"])
            sources.append(vernaculars[irn]["source"])
        else:
            vernaculars_names.append(name)
            sources.append(src)

    taxonomy_df["vernacular_name"] = vernaculars_names
    taxonomy_df["vernacular_name_source"] = sources
    catalogue_df["gbif_id"] = gbif_ids

    return catalogue_df, taxonomy_df
