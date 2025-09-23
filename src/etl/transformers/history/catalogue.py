import pandas as pd

from ..utils import flatten_field, rename_dict_keys, to_pg_array


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

    df["creators"] = df["CreatorGroup"].apply(
        lambda x: x if isinstance(x, list) else []
    )

    df.drop(columns=["CreatorGroup"], inplace=True)

    df["creators"] = df["creators"].apply(
        lambda creator_list: [
            rename_dict_keys(
                creator,
                {
                    "CreName": "name",
                    "CreRole": "role",
                    "CreDateCreated": "date_created",
                },
            )
            for creator in creator_list
            if isinstance(creator, dict)
        ]
    )

    df["subjects"] = df["subjects"].apply(lambda x: x if isinstance(x, list) else [])

    df["subjects"] = df["subjects"].apply(
        lambda subject_list: [
            rename_dict_keys(subject, {"SubSubject": "name"})
            for subject in subject_list
            if isinstance(subject, dict)
        ]
    )

    return df
