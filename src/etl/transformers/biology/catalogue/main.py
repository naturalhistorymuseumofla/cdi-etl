import pandas as pd

from etl.transformers.biology.elements.main import transform_biology_elements

from .sex import clean_caste, clean_life_stage, clean_sex
from .side import clean_side
from .type_status import clean_type_status


def transform_biology_catalogue(
    df: pd.DataFrame, taxa_irn: pd.Series, elements: list
) -> pd.DataFrame:
    """
    Transforms the biology catalogue DataFrame by cleaning and normalizing fields.
    Args:
        df: The input biology catalogue DataFrame.
        taxa_irn: Series containing the IRN values for taxa.
    Returns:
        A list containing the transformed biology catalogue DataFrame and
        a DataFrame representing the join table between catalogue records and elements.
    """

    df["sex"] = df["sex"].apply(clean_sex)
    df["caste"] = df["sex"].apply(clean_caste)
    df["life_stage"] = df["sex"].apply(clean_life_stage)
    df["side"] = df["side"].apply(clean_side)
    df["type_status"] = df["type_status"].apply(clean_type_status)
    df["department"] = df["department"].apply(lambda x: x.lower())
    df["date_emu_record_modified"] = df["date_emu_record_modified"].astype(str)
    df["verbatim_element"] = df["element"].copy()
    df["taxon_irn"] = pd.to_numeric(
        df["taxon_irn"], errors="coerce", downcast="integer"
    ).astype("Int64")
    df["locality_irn"] = pd.to_numeric(
        df["locality_irn"], errors="coerce", downcast="integer"
    ).astype("Int64")

    # remove df rows where taxon_irn is not in taxa_irn
    valid = set(taxa_irn)
    df = df[df["taxon_irn"].isin(valid)].copy()

    elements_df, elements_join_df = transform_biology_elements(elements, df)

    df = df.drop(columns=["element", "element_group", "operation"])

    return df, elements_df, elements_join_df
