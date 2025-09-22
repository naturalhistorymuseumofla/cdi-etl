import pandas as pd

from .elements import clean_element
from .sex import clean_caste, clean_life_stage, clean_sex
from .side import clean_side
from .type_status import clean_type_status


def transform_biology_catalogue(df: pd.DataFrame) -> pd.DataFrame:
    """
    Transforms the biology catalogue DataFrame by cleaning and normalizing fields.
    """

    df["sex"] = df["sex"].apply(clean_sex)
    df["caste"] = df["sex"].apply(clean_caste)
    df["life_stage"] = df["sex"].apply(clean_life_stage)
    df["element"] = df["element"].apply(clean_element)
    df["side"] = df["side"].apply(clean_side)
    df["type_status"] = df["type_status"].apply(clean_type_status)
    df["department"] = df["department"].apply(lambda x: x.lower())
    df["date_emu_record_modified"] = df["date_emu_record_modified"].astype(str)

    return df
