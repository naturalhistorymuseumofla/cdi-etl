import re

import pandas as pd
from culture_matcher import CultureMatcher
from utils import flatten_field, to_pg_array


def clean_material_term(term):
    """Remove parentheses content and question marks"""
    if pd.isna(term):
        return ""
    term = re.sub(r"\([^)]*\)", "", str(term))
    term = term.replace("?", "")
    term = " ".join(term.split())
    return term.strip()


def transform_anthropology_catalogue(
    df: pd.DataFrame, cultures: pd.DataFrame
) -> pd.DataFrame:
    """
    Transforms the anthropology catalogue DataFrame by cleaning and normalizing fields.

    Args:
        df: The input DataFrame containing the anthropology catalogue data.
        cultures: A DataFrame containing culture information for matching.

    Returns:
        A transformed DataFrame with cleaned and normalized fields.
    """

    # Flatten the cultural attribution and material type fields
    df["cultural_attribution"] = flatten_field(df["cultural_attribution"], "AntMotif")
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

    return df
