import pandas as pd

from etl.extractors import xml_to_json
from etl.transformers.anthropology import transform_anthropology_catalogue
from etl.transformers.anthropology.cultures import Cultures

if __name__ == "__main__":
    records = xml_to_json("data/anthropology_catalogue.xml")
    catalogue_df = pd.DataFrame(records).fillna("")

    cultures = Cultures()
    cultures_df = cultures.get_cultures_dataframe()
    _, join_df = transform_anthropology_catalogue(catalogue_df)

    counts = join_df["cultures_id"].value_counts().to_dict()
    for id in cultures_df["id"]:
        count = counts.get(str(id), 0)
        # Get children counts
        all_children = cultures.get_descendant_ids(id)
        total_count = sum(counts.get(str(child_id), 0) for child_id in all_children)
        total_count += count
        record = cultures_df.query(f"id == {id}")
        cultures.update_record(
            record["record_id"].values[0],
            {"match_count": count, "recursive_match_count": total_count},
        )
