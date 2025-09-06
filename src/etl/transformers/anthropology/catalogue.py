import re

import pandas as pd
from typing import Tuple

from ..utils import flatten_field, to_pg_array
from .cultures import Cultures


def clean_material_term(term):
    """Remove parentheses content and question marks"""
    if pd.isna(term):
        return ""
    term = re.sub(r"\([^)]*\)", "", str(term))
    term = term.replace("?", "")
    term = " ".join(term.split())
    return term.strip()


def transform_anthropology_catalogue(
    df: pd.DataFrame,
) -> Tuple[pd.DataFrame, pd.DataFrame]:
    """
    Transforms the anthropology catalogue DataFrame by cleaning and normalizing fields.

    Args:
        df: The input DataFrame containing the anthropology catalogue data.

    Returns:
        A transformed DataFrame with cleaned and normalized fields.
    """

    # Flatten the cultural attribution and material type fields
    df["cultural_attribution"] = flatten_field(
        df["cultural_attribution"], field_name="AntMotif"
    )
    df["material_type_verbatim"] = flatten_field(
        df["material_type_verbatim"], "AntMaterial"
    )

    # Flatten the site references
    sites = [site[0] for site in df["AntSiteRef"]]
    sites = pd.DataFrame(sites).fillna("")
    sites["site_name"] = flatten_field(sites["site_name"], "SitSiteName")
    sites.drop(columns=["irn"], inplace=True)
    sites["site_name"] = sites["site_name"].apply(lambda x: to_pg_array(x))

    # Reset the index of the DataFrames, combine two dataframes
    df = df.reset_index(drop=True)
    sites = sites.reset_index(drop=True)
    df = pd.concat([df, sites], axis=1)

    # Clean material_type
    materials = df["material_type_verbatim"]
    cleaned_materials = []
    for material_list in materials:
        cleaned_material_list = []
        for material in material_list:
            term = clean_material_term(material)
            split_term = term.split(" - ")
            cleaned_material_list.append(
                {
                    "material_type": split_term[0],
                    "matieral_subtype": "" if len(split_term) < 2 else split_term[1],
                }
            )
        cleaned_materials.append(cleaned_material_list)
    df["material_type"] = cleaned_materials

    # Use Cultures to process cultural_attribution and build a join table
    cultures = Cultures()

    join_rows = []
    matched_ids_series = []

    for _, row in df.iterrows():
        # IRN identifies the catalogue record; fall back to index if missing
        irn = row.get("irn") if "irn" in row.index else None

        matched_ids: list = []
        if row.get("cultural_attribution"):
            # cultural_attribution is expected to be a list of motif strings
            matched_ids = cultures.match_list_ids(row["cultural_attribution"])
            for cid in matched_ids:
                join_rows.append({"catalogue_irn": irn, "cultures_id": cid})

        matched_ids_series.append(matched_ids)

    # attach the list of matched culture ids to the catalogue rows for convenience
    df["cultures_ids"] = matched_ids_series

    # build join table DataFrame
    join_df = pd.DataFrame(join_rows, columns=["catalogue_irn", "cultures_id"])

    return df, join_df
