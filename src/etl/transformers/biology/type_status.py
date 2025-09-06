def clean_type_status(type_status: str) -> str:
    """Cleans EMu typeStatus column and transforms into dwc:typeStatus"""

    if not type_status:
        return ""

    cleaned_val = type_status.replace("?", "").strip().lower()

    type_statuses = {
        "cited lot": "hypotype",
        "hypotype": "hypotype",
        "cotype": "syntype",
        "neotype": "neotype",
        "neo": "neotype",
        "figured": "hypotype",
        "holo": "holotype",
        "holotype": "holotype",
        "paralectotype": "paralectotype",
        "lectotype": "lectotype",
        "lecto": "lectotype",
        "para": "paratype",
        "syn": "syntype",
        "syntype": "syntype",
        "unfigured": "hypotype",
    }

    stage = [
        type_statuses[status]
        for status in type_statuses.keys()
        if status in cleaned_val
    ]

    if stage:
        return stage[0]
    else:
        return ""
