import uuid
import re

import pandas as pd

from ..utils import to_pg_array


def clean_color(color: str) -> list[str]:
    """Clean the color string by removing leading/trailing spaces and converting to lowercase."""
    if not color or pd.isna(color):
        return []

    if not isinstance(color, str) and color.startswith("["):
        return []

    color = color.replace("nan,", "").replace("nan", "").strip()

    # color = ast.literal_eval(color)[0]

    cleaned_colors = []

    if not isinstance(color, str):
        return []

    color = color.lower()
    colors_list = re.split(r"\s*[&,/-]\s*|\s*to\s*", color)
    colors_list = [c.replace(",", "") for c in colors_list]
    cleaned_colors += colors_list

    color_dict = {
        "golden": "gold",
        "lavender": "purple",
        "olive": "green",
        "salmon": "salmon",
        "aqua": "light blue",
        "violet": "purple",
        "pale": "",
        "forest": "green",
        "rose": "pink",
        "peach": "pink",
        "amethystine": "purple",
        "honey": "gold",
        "bronze": "orange",
        "pinkish": "pink",
        "brassy": "gold",
        "or": "orange",
        "hyacinth": "",
        "copper": "orange",
        "yellow": "yellow",
        "irridescent": "",
        "mustard": "yellow",
        "m": "",
        "f": "",
        "straw": "yellow",
        "iridescent": "",
        "lilac": "purple",
        "padparadsha": "salmon",
        "orchid": "",
        "iridescent red": "red",
        "chartreuse": "green",
        "green": "green",
        "blue": "blue",
        "purple": "purple",
        "red": "red",
        "orange": "orange",
        "brown": "brown",
        "black": "black",
        "white": "white",
        "gray": "gray",
        "grey": "gray",
        "pink": "pink",
        "beige": "beige",
        "colorless": "colorless",
        "clear": "colorless",
        "transparent": "colorless",
        "cream": "cream",
        "silver": "silver",
        "gold": "gold",
        "tan": "tan",
        "golden": "gold",
        "padparadsha": "salmon",
    }

    cleaned_colors = [
        color_dict[c] for c in cleaned_colors if c in color_dict and color_dict[c] != ""
    ]

    # Remove duplicates
    cleaned_colors = list(set(cleaned_colors))

    return cleaned_colors


def transform_mineralogy_specimens(df: pd.DataFrame) -> list[dict]:
    """
    Transforms the mineralogy specimens DataFrame by cleaning and normalizing fields.
    """

    records = df[["irn", "specimen_taxon_group", "mineral_group"]].to_dict(
        orient="records"
    )

    specimens = []

    for record in records:
        if not isinstance(record["mineral_group"], list):
            # specimens.append([])
            continue
        primary_specimen_irn = record["specimen_taxon_group"][0].get(
            "specimen_taxon_irn", ""
        )
        # catalogue_specimens = []
        for mineral in record["mineral_group"]:
            if not mineral.get("mineral_taxon_irn"):
                continue
            is_primary_specimen = primary_specimen_irn == mineral.get(
                "mineral_taxon_irn"
            )
            # Create a composite key to ensure uniqueness
            composite_key = (
                f"{record['irn']}_"
                f"{mineral.get('mineral_taxon_irn')}_"
                f"{mineral.get('MinVariety', 'no-variety')}_"
                f"{mineral.get('MinColor', 'no-colors')}_"
                f"{mineral.get('MinHabit', 'no-habit')}_"
                f"{mineral.get('MinDisplayQual', 'no-display')}"
            )
            # Hash composite key
            # composite_key = hashlib.md5(composite_key.encode()).hexdigest()
            uid = uuid.uuid5(uuid.NAMESPACE_DNS, composite_key)
            composite_key = str(uid)
            is_display_quality = mineral.get("MinDisplayQual", "").lower() == "yes"
            specimen = {
                "specimen_id": composite_key,
                "taxonomy_irn": mineral.get("mineral_taxon_irn"),
                "catalogue_irn": record["irn"],
                "is_primary_specimen": is_primary_specimen,
                "variety": mineral.get("MinVariety", None),
                "is_display_quality": is_display_quality,
                "verbatim_colors": mineral.get("MinColor", None),
                "colors": clean_color(mineral.get("MinColor", "")),
                "habit": mineral.get("MinHabit", None),
            }
            specimens.append(specimen)
        # specimens.append(catalogue_specimens)

    specimens_df = pd.DataFrame(specimens)

    # Remove duplicates based on specimen_id
    specimens_df = specimens_df.drop_duplicates(
        subset=["specimen_id"], keep="first"
    ).reset_index(drop=True)

    return specimens_df
