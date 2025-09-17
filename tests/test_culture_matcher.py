from typing import List, Set

from etl.transformers.anthropology.cultures import Cultures

cultures = Cultures()


def match(motif: str) -> Set[str]:
    matches = cultures.match(motif)
    if matches:
        return {
            cultures.get_name_by_id(id) for id in matches if cultures.get_name_by_id(id)
        }
    return set()


def match_list(motifs: List[str]) -> Set[str]:
    matches = cultures.match_list(motifs)
    if matches:
        return {
            cultures.get_name_by_id(id) for id in matches if cultures.get_name_by_id(id)
        }
    return set()


def test_match():
    # Basic test
    assert match("possibly Ica") == {"Ica"}
    assert match("Apinage") == {"Apinajé"}
    assert match("Samoan") == {"Samoan"}
    assert match("Tsimshian") == {"Tsimshian"}

    # Match on match_term
    assert match("Egyptian (general)") == {"Modern Egyptian"}

    # Test separators
    assert match("Senufo/Senoufo") == {"Senufo"}
    assert match("Achomawi/Achumawi (Pit River Tribe)") == {
        "Achomawi",
        "Pit River Tribe",
    }
    assert match("Bannock (Banate) - Nez Perce (Nimiipuu)") == {
        "Nez Perce",
        "Bannock",
    }
    assert match("Pawnee (Chaticks-si-Chaticks); Osage style") == {
        "Pawnee",
        "Osage",
    }

    # Test diacritic markers
    assert match("Chimu") == {"Chimú"}

    # Test empty and None inputs
    assert match("") == set()
    assert match(None) == set()  # type: ignore


def test_match_list():
    assert match_list(["Abnaki/Abenaki (Alnobak)"]) == {"Abenaki"}

    assert match_list(None) == set()  # type: ignore
    assert match_list(None) == set()  # type: ignore
