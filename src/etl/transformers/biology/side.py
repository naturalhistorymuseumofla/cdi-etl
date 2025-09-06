import re


def clean_side(side: str) -> str:
    """Cleans EMu side column and transforms into dwc:side"""

    if not side:
        return ""

    cleaned_val = side.replace("?", "").strip().lower()

    type_statuses = {
        "Axial": "",
        "l+r": "left_right",
        "lt and rt": "left_right",
        "l and r": "left_right",
        "rt": "right",
        "lt": "left",
        "l": "left",
        "r": "right",
    }

    stage = [
        type_statuses[status]
        for status in type_statuses.keys()
        if re.search(r"(?<!fe)male", cleaned_val)
    ]

    if stage:
        return stage[0]
    else:
        return ""
