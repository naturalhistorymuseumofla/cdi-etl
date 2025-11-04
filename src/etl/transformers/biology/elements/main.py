from .elements import Elements
import pandas as pd


def transform_biology_elements(elements: list[dict], catalogue_df) -> Elements:
    elements = Elements(elements)

    elements_join_table = []
    for record in catalogue_df[["irn", "element"]].values.tolist():
        irn, element = record
        matches = elements.match(element)
        if not matches:
            continue
        for match in matches:
            if not match.get("id"):
                continue
            elements_join_table.append(
                {"catalogue_irn": irn, "element_id": match["id"]}
            )

    elements_join_df = pd.DataFrame(elements_join_table)
    return elements.get_elements(), elements_join_df
