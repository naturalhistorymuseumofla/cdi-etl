"""
Utilities to build/export a CSV mapping AntMotif-like terms to canonical culture names.

This module is designed to be imported and called from VS Code (Run File / Debug / Interactive)
rather than run as a CLI tool. Use `export_antmotif_df()` to get a DataFrame (and optionally
write it to disk).

Example (in VS Code Python Interactive or a debug session):
    from scripts.cultures_match import export_antmotif_df
    df = export_antmotif_df(out_path="data/antmotif_to_culture.csv")
"""

import pandas as pd

from etl.extractors import xml_to_json
from etl.transformers.anthropology.cultures import Cultures
from etl.transformers.utils import flatten_field

# Optional: keep __main__ small and non-CLI to allow file -> Run in VS Code
if __name__ == "__main__":
    records = xml_to_json("data/anthropology_catalogue.xml")
    catalogue_df = pd.DataFrame(records).fillna("")

    cultures = Cultures()
    cultures_df = cultures.get_cultures_dataframe()

    motifs = flatten_field(catalogue_df["cultural_attribution"], "AntMotif")
    motifs = [m for m in motifs if m]

    motif_counts = pd.Series(motifs).value_counts().to_frame()

    matched_cultures = []
    for motif in motif_counts.index:
        matches = cultures.match_list(motif)
        matches = [cultures.get_name_by_id(id) for id in matches]
        matched_cultures.append(matches)

    motif_counts["matches"] = matched_cultures
    motif_counts.reset_index(inplace=True)
    motif_counts.columns = ["AntMotif", "count", "matches"]

    motif_counts.to_csv("data/antmotif-culture-matches.csv", index=False)
