import pandas as pd


def transform_biology_taxonomy(taxonomy: dict) -> pd.DataFrame:
    """
    Transforms the biology taxonomy data into a DataFrame.
    Args:
        taxonomy: The input biology taxonomy data as a dictionary.
    Returns:
        A DataFrame representing the transformed biology taxonomy.
    """
    taxonomy_df = pd.DataFrame(taxonomy)

    # Rename columns for clarity
    taxonomy_df.rename(
        columns={
            "RanParentRef": "parent_irn",
            "ClaCurrentNameRef": "current_name_irn",
        },
        inplace=True,
    )

    taxonomy_df["parent_irn"] = taxonomy_df["parent_irn"].apply(
        lambda x: x[0].get("parent_id") if x else None
    )
    taxonomy_df["current_name_irn"] = taxonomy_df["current_name_irn"].apply(
        lambda x: x[0].get("current_name_irn") if x else None
    )
    taxonomy_df["department"] = taxonomy_df["department"].apply(
        lambda x: x.lower() if isinstance(x, str) else x
    )

    # Clean 'commonName' column by replacing NaN and None with empty strings
    taxonomy_df["common_name"] = taxonomy_df["common_name"].replace(
        {pd.NA: "", None: "", float("nan"): ""}
    )

    # Extract vernacular name from 'common_name' field
    taxonomy_df["vernacular_name"] = taxonomy_df["common_name"].apply(
        lambda x: x[0].get("ComName").capitalize() if x else None
    )

    # Set vernacular name source
    taxonomy_df["vernacular_name_source"] = [
        "NHMLAC" if name and name != "" else "" for name in taxonomy_df["common_name"]
    ]

    # Convert to integer type
    taxonomy_df["parent_irn"] = taxonomy_df["parent_irn"].astype("Int64")
    taxonomy_df["current_name_irn"] = taxonomy_df["current_name_irn"].astype("Int64")
    taxonomy_df["irn"] = taxonomy_df["irn"].astype("Int64")

    taxonomy_df.drop(columns=["currently_accepted", "common_name"], inplace=True)
    return taxonomy_df
