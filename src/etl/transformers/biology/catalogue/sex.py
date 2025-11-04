import re


def clean_life_stage(sex: str) -> str:
    """Cleans sex col from EMu and transforms into dwc:lifeStage"""
    if not sex:
        return ""

    cleaned_val = sex.replace("?", "").strip().lower()

    life_stages = {
        "tadpole": "tadpole",
        "subadult": "subadult",
        "adult": "adult",
        "juvenile": "juvenile",
        "pupae": "pupa",
        "pupa": "pupa",
        "imago": "adult",
        "egg": "egg",
        "larvae": "larvae",
        "larva": "larvae",
        "larval": "larvae",
        "nymph": "nymph",
        "immature": "juvenile",
        "queen": "adult",
        "worker": "adult",
        "soldier": "adult",
        "alate": "adult",
        "dealate": "adult",
        "puparia": "larvae",
        "hatchling": "hatchling",
        "triungulin": "triungulin",
        "instar I": "instar I",
        "instar II": "instar II",
        "instar III": "instar III",
        "instar IV": "instar IV",
        "instar V": "instar V",
        "instar VI": "instar VI",
        "instar VII": "instar VII",
        "instar VIII": "instar VIII",
    }

    stage = [life_stages[stage] for stage in life_stages.keys() if stage in cleaned_val]

    if stage:
        return stage[0]

    else:
        return ""


def clean_sex(sex: str) -> str:
    """Cleans EMu sex column and transforms into dwc:sex"""
    if not sex:
        return ""

    cleaned_val = sex.replace("?", "").strip().lower()

    is_female = "female" in cleaned_val or "f" == cleaned_val
    is_male = re.search(r"(?<!fe)male", cleaned_val) or "m" == cleaned_val

    sex = ""

    if is_male and is_female:
        sex = "female_male"
    elif is_female and not is_male:
        sex = "female"
    elif is_male and not is_female:
        sex = "male"

    return sex


def clean_caste(sex: str) -> str:
    """Cleans EMu sex col and transforms into dwc:caste"""
    if not sex:
        return ""

    cleaned_val = sex.replace("?", "").strip().lower()

    castes = {
        "queen": "queen",
        "worker": "worker",
        "soldier": "soldier",
        "alate": "alate",
        "dealate": "dealate",
    }
    caste = [castes[c] for c in castes.keys() if c in cleaned_val]

    if caste:
        return caste[0]
    else:
        return ""
