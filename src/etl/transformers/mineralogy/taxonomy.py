import ast
import unicodedata

import pandas as pd

from config.settings import settings

from ..utils import to_pg_array


def clean_is_valid(x: str):
    if x.strip().lower() in ["yes", "true", "1"]:
        return True
    return False


def safe_literal_eval(x):
    if isinstance(x, list):
        return x
    if not isinstance(x, str):
        return []
    s = x.replace("nan", "None")
    try:
        val = ast.literal_eval(s)
        if isinstance(val, list):
            return val
        else:
            return []
    except Exception:
        return []


# Normalize strings to remove diacritics and special characters
def normalize_string(s: str):
    if isinstance(s, str):  # Ensure it's a string
        normalized = unicodedata.normalize("NFD", s)
        return (
            "".join(c for c in normalized if unicodedata.category(c) != "Mn")
            .replace("ø", "o")
            .replace("Ø", "O")
        )
    return s  # Return non-string inputs as is


# Clean the mineral names for merging
def clean_name(name: str):
    """Clean the mineral name from Mindat."""
    return (
        name.lower()
        .replace("(", "")
        .replace(")", "")
        .replace("’", "'")
        .strip()
        .replace(" ", "")
    )


def transform_mineralogy_taxonomy(minerals_df: pd.DataFrame) -> pd.DataFrame:
    """
    Transforms the mineralogy catalogue DataFrame by cleaning and normalizing fields.
    """

    mindat_geomaterials_url = settings.mindat_geomaterials_url

    if not mindat_geomaterials_url:
        raise ValueError("MINDAT_GEOMATERIALS_URL is not set in environment variables.")

    cols = [
        "id",
        "name",
        "mindat_formula",
        "ima_status",
        "ima_notes",
        "varietyof",
        "synid",
        "groupid",
        "entrytype_text",
        "description_short",
        "elements",
        "cleavage",
        "parting",
        "tenacity",
        "strunz10ed1",
        "strunz10ed2",
        "strunz10ed3",
        "strunz10ed4",
        # "dana8ed1",
        # "dana8ed2",
        # "dana8ed3",
        # "dana8ed4",
        "rock_parent",
        "rock_parent2",
        "rock_root",
        "rock_bgs_code",
        "meteoritical_code",
    ]

    mindat_df = pd.read_csv(mindat_geomaterials_url)[cols]
    mindat_df["name"] = mindat_df["name"].apply(normalize_string)

    # Drop unneeded rows from Mindat DataFrame
    mindat_df["sort_key"] = mindat_df["entrytype_text"] != "synonym"

    # Sort the DataFrame by 'sort_key' (descending so True comes first) and then by 'name'
    mindat_df_sorted = mindat_df.sort_values(
        by=["sort_key", "name"], ascending=[False, True]
    )

    # Drop duplicates based on 'name', keeping the first occurrence (which is the non-synonym)
    mindat_df = mindat_df_sorted.drop_duplicates(subset=["name"], keep="first")

    # Drop the temporary sort_key column
    mindat_df = mindat_df.drop(columns=["sort_key"])

    mindat_df["merge_key"] = mindat_df["name"].apply(clean_name)
    minerals_df["merge_key"] = minerals_df["species"].apply(clean_name)

    minerals_merged = pd.merge(
        minerals_df, mindat_df, on="merge_key", how="left", suffixes=("", "_mindat")
    )

    # Columns to rename
    columns_map = {
        "irn": "irn",
        "id": "mindat_id",
        "name": "mindat_name",
        "mindat_formula": "mindat_formula",
        "ima_status": "mindat_ima_status",
        "ima_notes": "mindat_ima_notes",
        "varietyof": "mindat_variety_of",
        "synid": "mindat_syn_id",
        "groupid": "mindat_group_id",
        "entrytype_text": "mindat_entry_type",
        "description_short": "mindat_description",
        "elements": "mindat_elements",
        "tenacity": "mindat_tenacity",
        "strunz10ed1": "mindat_strunz_1",
        "strunz10ed2": "mindat_strunz_2",
        "strunz10ed3": "mindat_strunz_3",
        "strunz10ed4": "mindat_strunz_4",
        "dana8ed1": "mindat_dana_1",
        "dana8ed2": "mindat_dana_2",
        "dana8ed3": "mindat_dana_3",
        "dana8ed4": "mindat_dana_4",
        "rock_parent": "mindat_rock_parent",
        "rock_parent2": "mindat_rock_grandparent",
        "meteoritical_code": "mindat_meteoritical_code",
    }

    # Rename the columns for clarity
    taxonomy_df = minerals_merged.rename(columns=columns_map)

    # Convert float cols to int
    float_cols = [
        "mindat_id",
        "mindat_syn_id",
        "mindat_variety_of",
        "mindat_group_id",
        "mindat_syn_id",
        "mindat_group_id",
        "mindat_rock_parent",
        "mindat_rock_grandparent",
        "mindat_meteoritical_code",
    ]

    def convert_to_int(x):
        if pd.isna(x):
            return None
        if not x:
            return None
        try:
            return int(x)
        except (ValueError, TypeError):
            return None

    for col in float_cols:
        taxonomy_df[col] = taxonomy_df[col].astype("Int64", errors="ignore")
        # taxonomy_df[col] = taxonomy_df[col].apply(lambda x: convert_to_int(x))

    # taxonomy_df["is_valid"] = taxonomy_df["is_valid"].apply(clean_is_valid)
    taxonomy_df["mindat_elements"] = taxonomy_df["mindat_elements"].apply(
        lambda x: to_pg_array(x.split(" "))
    )
    taxonomy_df["mindat_ima_status"] = taxonomy_df["mindat_ima_status"].apply(
        lambda x: to_pg_array(safe_literal_eval(x))
    )

    taxonomy_df["mindat_ima_notes"] = taxonomy_df["mindat_ima_notes"].apply(
        lambda x: to_pg_array(safe_literal_eval(x))
    )

    taxonomy_df["is_valid"] = (
        taxonomy_df["is_valid"]
        .fillna("")
        .apply(lambda x: True if "yes" in x.lower() else False)
    )

    # Remove duplicates
    taxonomy_df = taxonomy_df.sort_values(by=["mindat_entry_type"])
    taxonomy_df = taxonomy_df.drop_duplicates(subset=["irn"], keep="first")

    # Convert data types
    taxonomy_df["mindat_strunz_1"] = (taxonomy_df["mindat_strunz_1"]).astype(
        "Int64", errors="ignore"
    )

    taxonomy_df["mindat_strunz_2"] = taxonomy_df["mindat_strunz_2"].apply(
        lambda x: x if x else None
    )
    taxonomy_df["mindat_strunz_3"] = taxonomy_df["mindat_strunz_3"].apply(
        lambda x: x if x else None
    )
    taxonomy_df["mindat_strunz_4"] = taxonomy_df["mindat_strunz_4"].apply(
        lambda x: x if x else None
    )

    # Drop unneeded columns
    taxonomy_df.drop(
        columns=[
            "elements_mindat",
            "rock_root",
            "mindat_meteoritical_code",
            "rock_bgs_code",
            "cleavage",
            "parting",
            "merge_key",
        ],
        inplace=True,
    )

    # Replace NaN with None to make the DataFrame JSON-compliant
    taxonomy_df = taxonomy_df.where(pd.notnull(taxonomy_df), None)

    return taxonomy_df
