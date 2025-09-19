import re
from typing import Any, Tuple

import pandas as pd

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


def fill_na(series: pd.Series, na_value: Any) -> None:
    """Fill NaN values with empty strings in string columns of a DataFrame."""
    series.fillna(na_value, inplace=True)


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
            matched_ids = cultures.match_list(row["cultural_attribution"])
            for cid in matched_ids:
                join_rows.append({"catalogue_irn": irn, "cultures_id": cid})

        matched_ids_series.append(matched_ids)

    # attach the list of matched culture ids to the catalogue rows for convenience
    df["cultures_ids"] = matched_ids_series

    # build join table DataFrame
    join_df = pd.DataFrame(join_rows, columns=["catalogue_irn", "cultures_id"])

    # Drop "cultures_id" column
    df.drop(columns=["cultures_ids"], inplace=True)

    # Rename columns to match target schema
    df.rename(
        columns={
            "AntSiteRef": "sites",
            "AntDonorRef": "donors",
            "AntCollectedByRef": "collectors",
        },
        inplace=True,
    )

    # Impose data types
    df["date_received"] = (
        df["date_received"]
        .apply(lambda v: "" if pd.isna(v) else str(v))
        .astype("string")
    )

    # Convert empty values to correct types
    df["collectors"] = df["collectors"].apply(
        lambda x: x if x != [{"irn": "", "collected_by": ""}] else []
    )
    df["donors"] = df["donors"].apply(
        lambda x: x if x != [{"irn": "", "donated_by": ""}] else []
    )
    df["sites"] = df["sites"].apply(
        lambda x: x
        if x != [{"irn": "", "site_name": "", "site_number": "", "site_summary": ""}]
        else []
    )
    df["site_name"] = df["site_name"].apply(lambda x: x if x != [""] else [])

    fill_na(df["cultural_attribution"], [])

    # Replace empty strings with None for JSON compatibility
    df.replace({"": None}, inplace=True)

    return df, join_df
