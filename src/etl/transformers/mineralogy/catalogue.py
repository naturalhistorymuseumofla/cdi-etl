import re

import pandas as pd


def clean_mineral_size(size: str) -> str:
    """Clean the mineral size string by removing leading/trailing spaces and converting to lowercase."""
    cleaned_size = size.strip().lower() if isinstance(size, str) else size

    size_dict = {
        "lc": "large cabinet",
        "mc": "micromount",
        "cb": "cabinet",
        "tn (thumbnail)": "thumbnail",
        "tn": "thumbnail",
        "sc": "small cabinet",
        "sm": "small",
        "mn": "mn",
        "Round Gem (~4 cm ID)": "round gem",
        "ov": "oversized",
        "standard box 1 (5.5x4.5x4 cm)": "box 1",
        "standard box 2 (8.5x5.5x4 cm)": "box 2",
        "standard box 3 (11.5x9x4 cm)": "box 3",
        "standard box 4 (15x10x4 cm)": "box 4",
        "standard box 5 (18x11.5x4 cm)": "box 5",
        "standard box 6 (23x18x4 cm)": "box 6",
        "tn (toenail; 54x54x38 mm)": "toenail",
        "display box (6.5x6.5x6 cm)": "display box",
        "mc (micromount)": "micromount",
    }

    return size_dict.get(cleaned_size, "")


# Apply the cleaning function to the 'size' column
def clean_dimensions(dimensions: str) -> list[float] | list[None]:
    """Clean the dimensions string by removing leading/trailing spaces and converting to lowercase."""
    pattern = r"^\d+(\.\d+)?\s*x\s*\d+(\.\d+)?(\s*x\s*\d+(\.\d+)?)?(?:x)?$"
    dimensions = (
        dimensions.strip().lower() if isinstance(dimensions, str) else dimensions
    )
    null_dimensions = [None, None, None]

    if not re.match(pattern, dimensions):
        return null_dimensions

    dimensions_list = dimensions.replace("'", "").replace("x", "").split(" ")

    dimensions_list = [
        float(d) for d in dimensions_list if d.replace(".", "", 1).isdigit()
    ]
    if len(dimensions_list) < 2:
        return null_dimensions

    if len(dimensions_list) == 2:
        dimensions_list.append(
            None  # type: ignore[return-value]
        )  # Add a height of None if only length and width are provided

    return dimensions_list[:3]


def assign_box(size, dimensions: list[float]) -> str:
    """Assign a box type based on the dimensions of the mineral."""
    # Check if size is a box size
    sizes = {
        "box 1": "box 1",
        "box 2": "box 2",
        "box 3": "box 3",
        "box 4": "box 4",
        "box 5": "box 5",
        "box 6": "box 6",
        "micromount": "micromount",
        "toenail": "box 1",
        "display box": "box 2",
    }
    if size in sizes:
        return sizes[size]

    # If size is not a box size, determine the box type based on dimensions
    if len(dimensions) < 2:
        return ""
    [w, l] = sorted(dimensions[0:2])

    box = ""
    box = "large" if w > 180.0 or l > 230.0 else box
    box = "box 6" if w <= 180.0 and l <= 230.0 else box
    box = "box 5" if w <= 110.5 and l <= 180.0 else box
    box = "box 4" if w <= 100.0 and l <= 150.0 else box
    box = "box 3" if w <= 90.0 and l <= 110.5 else box
    box = "box 2" if w <= 50.5 and l <= 80.5 else box
    box = "box 1" if w <= 40.5 and l <= 50.5 else box

    return box


def transform_mineralogy_catalogue(
    df: pd.DataFrame,
) -> pd.DataFrame:
    """
    Transforms the mineralogy catalogue DataFrame by cleaning and normalizing fields.

    Args:
        df: The input DataFrame containing the mineralogy catalogue data.

    Returns:
        A transformed DataFrame with cleaned and normalized fields.

    """

    df.drop(columns=["department"], inplace=True)
    df["category"] = df["category"].apply(
        lambda x: x.lower() if isinstance(x, str) else x
    )
    df["verbatim_size"] = df["size"]
    df["size"] = df["verbatim_size"].apply(clean_mineral_size)
    dimensions = df["dimensions"].apply(clean_dimensions)
    df[["length", "width", "height"]] = pd.DataFrame(
        dimensions.to_list(), index=df.index
    )
    return df
