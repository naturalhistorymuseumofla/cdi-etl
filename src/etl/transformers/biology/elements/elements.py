import pandas as pd
from ...utils import to_pg_array


class Elements:
    """Class to hold element data fetched from Airtable"""

    def __init__(self, elements: list[dict]):
        self.elements = self.airtable_to_dataframe(elements)
        self.lookup = self._build_elements_lookup(self.elements)

    @staticmethod
    def _build_elements_lookup(elements: pd.DataFrame) -> None:
        """
        Builds a lookup dictionary mapping all possible names and synonyms to the main element name.
        """
        lookup = {}
        for _, row in elements.iterrows():
            main_name = str(row["name"]).strip()
            if main_name:
                lookup[main_name.lower()] = {
                    "name": main_name,
                    "id": row["id"],
                    "record_id": row["record_id"],
                    "parent_name": row.get("parent_name", ""),
                    "accept_partial_match": row.get("accept_partial_match", False),
                    "children_count": len(row.get("children", [])),
                }
            synonyms = row.get("synonyms")
            if synonyms:
                for synonym in synonyms:
                    synonym = synonym.strip()
                    if synonym:
                        lookup[synonym.lower()] = {
                            "name": main_name,
                            "record_id": row["record_id"],
                            "parent_name": row.get("parent_name", ""),
                            "accept_partial_match": row.get(
                                "accept_partial_match", False
                            ),
                            "children_count": len(row.get("children", [])),
                        }
        # Primary sort: children_count (descending) so entries with more children
        # are prioritized. Secondary sort: key length (descending) so longer
        # keys are matched before shorter ones when doing substring matches.
        # Sort so entries with fewer children come first, and for equal
        # children_count prefer longer keys (so we still match longer names first).
        sorted_items = sorted(
            lookup.items(),
            key=lambda kv: (kv[1].get("children_count", 0), -len(kv[0])),
        )

        # Return a dict with insertion order matching our sort.
        return dict(sorted_items)

    @staticmethod
    def airtable_to_dataframe(records: list[dict]) -> pd.DataFrame:
        """Fetches all records from the given Airtable table and converts them to a DataFrame."""
        elements = pd.DataFrame([record["fields"] for record in records]).fillna("")
        elements["record_id"] = [record["id"] for record in records]
        elements["synonyms"] = elements["synonyms"].apply(lambda x: x if x else [])

        def to_list(x):
            return x if isinstance(x, list) else []

        elements["parent_name"] = elements["parent_name"].apply(to_list)
        elements["parent_id"] = elements["parent_id"].apply(to_list)

        return elements

    @staticmethod
    def _clean_element(element: str) -> str:
        """Cleans and normalizes the element name using the provided lookup dictionary."""
        if not isinstance(element, str) or not element.strip():
            return ""

        return element.replace("?", "").strip().lower()

    def match(self, element: str) -> list[dict] | None:
        """
        Matches an element string to element names, excluding any that are parents of other matched cultures.

        Args:
            element: The element term string.

        Returns:
            A matched element record as a list of dicts, or None if no match made.
        """
        if not element or not isinstance(element, str):
            return None

        cleaned_element = self._clean_element(element)

        matches = []

        # Iterate over sorted keys to prioritize longer matches first
        for key, value in self.lookup.items():
            if key in cleaned_element:
                matches.append(value)
                break

        return matches

    def get_elements(self) -> pd.DataFrame:
        """Returns the elements DataFrame."""
        df = self.elements.copy()
        df = df[
            [
                "id",
                "name",
                "domains",
                "synonyms",
                "uberon_id",
                "description",
                "parent_id",
            ]
        ]
        df["parent_id"] = (
            df["parent_id"]
            .apply(lambda x: x[0] if isinstance(x, list) and x else None)
            .astype("Int64")
        )
        df["synonyms"] = df["synonyms"].apply(
            lambda x: to_pg_array(x) if isinstance(x, list) else to_pg_array([])
        )
        df["domains"] = df["domains"].apply(
            lambda x: to_pg_array(x) if isinstance(x, list) else to_pg_array([])
        )
        return df
