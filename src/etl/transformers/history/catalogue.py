import pandas as pd

from ..utils import flatten_field, to_pg_array


def transform_history_catalogue(
    df: pd.DataFrame,
) -> pd.DataFrame:
    """
    Transforms the history catalogue DataFrame by cleaning and normalizing fields.

    Args:
        df: The input DataFrame containing the history catalogue data.

    Returns:
        A transformed DataFrame with cleaned and normalized fields.

    """
    # Implement the transformation logic here

    df["creators"] = df["CreatorGroup"].apply(flatten_field, field_name="CreRole")

    return df
