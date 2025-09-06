import pandas as pd

from etl.transformers.anthropology.cultures import Cultures


def make_sample_cultures_df():
    """Return a small DataFrame that represents cultures with synonyms and parents.

    Structure:
      A (synonyms: Alpha, Al)  -- no parent
      B (synonyms: Beta)       -- parent A
      C (synonyms: [])         -- parent B
      D (synonyms: Delta)      -- no parent
    """
    rows = [
        {"name": "A", "synonyms": ["Alpha", "Al"], "parent_culture": ""},
        {"name": "B", "synonyms": ["Beta"], "parent_culture": "A"},
        {"name": "C", "synonyms": [], "parent_culture": "B"},
        {"name": "D", "synonyms": ["Delta"], "parent_culture": ""},
    ]
    return pd.DataFrame(rows)


def test_extract_terms_various_formats():
    s = "Motif (Alpha, Beta) / Gamma - Delta or Epsilon"
    terms = Cultures.extract_terms(s)
    # Lowercased unique terms expected
    expected = {"alpha", "beta", "gamma", "delta", "epsilon", "motif"}
    assert set(terms) >= expected


def test_build_lookups_and_parents():
    df = make_sample_cultures_df()
    cm = Cultures(cultures=df)

    # culture_lookup should map synonyms and main names (lowercased) to main name
    lookup = cm.culture_lookup
    assert lookup.get("a") == "A"
    assert lookup.get("alpha") == "A"
    assert lookup.get("beta") == "B"
    assert lookup.get("delta") == "D"

    # parent_lookup should map child -> parent when present
    parent = cm.parent_lookup
    assert parent.get("B") == "A"
    assert parent.get("C") == "B"
    assert "A" not in parent or parent.get("A") == ""


def test_get_all_parents_chain():
    df = make_sample_cultures_df()
    cm = Cultures(cultures=df)

    parents_of_c = cm._get_all_parents("C")
    assert parents_of_c == {"B", "A"}


def test_match_children_only_and_synonyms():
    df = make_sample_cultures_df()
    cm = Cultures(cultures=df)

    # If motif contains both A and B terms, parent A should be removed and only B returned
    res = cm.match("Alpha / Beta")
    assert set(res) == {"B"}

    # Synonym matching for D
    res2 = cm.match("Delta")
    assert set(res2) == {"D"}

    # Matching C by name should return C
    res3 = cm.match("C")
    assert set(res3) == {"C"}
