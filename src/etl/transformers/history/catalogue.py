import pandas as pd


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
    df_cleaned = df.copy()
    df_cleaned.columns = (
        df_cleaned.columns.str.strip().str.lower().str.replace(" ", "_")
    )
    df_cleaned = df_cleaned.fillna("")

    return df_cleaned
