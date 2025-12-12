import pandas as pd


class GbifMatcher:
    """Class to match vernacular names from GBIF to internal taxonomy IDs."""

    def __init__(
        self,
        vernaculars: pd.DataFrame,
        occurences: pd.DataFrame,
    ):
        self.vernaculars = vernaculars
        self.occurences = occurences
        self.occurence_map = self._create_occurence_vernacular_map()

    def _create_occurence_vernacular_map(self) -> dict:
        """Creates a mapping from occurrence IDs to vernacular names."""

        # Merge occurences with vernacular names on taxonKey and taxonID
        merged = pd.merge(
            self.occurences,
            self.vernaculars,
            left_on="taxonKey",
            right_on="taxonID",
            how="left",
        ).dropna(subset=["vernacularName"])

        # Clean vernacular names
        merged["vernacularName"] = merged["vernacularName"].apply(
            lambda x: x.strip().capitalize()
        )

        def assign_source_weight(source):
            weights = {
                "IOC World Bird List, v13.2": 5,
                "The Paleobiology Database": 4,
                "Checklist of Vermont Species": 3,
                "Martha's Vineyard species checklist": 3,
                "Multilingual IOC World Bird List, v11.2": 2,
                "Catalogue of Life Checklist": 2,
                "The IUCN Red List of Threatened Species": 1,
            }
            return weights.get(source, 0)

        # Assign weights to sources for prioritization
        merged["source_weight"] = merged["source"].apply(assign_source_weight)
        merged.sort_values(
            by=["occurrenceID", "source_weight"], ascending=[True, False], inplace=True
        )
        # Keep only the highest priority vernacular name per occurrenceID
        merged = merged.drop_duplicates(subset=["occurrenceID"], keep="first")

        # Create the mapping dictionary
        map = {
            row.occurrenceID: {
                "vernacular_name": row.vernacularName,
                "source": row.source,
                "gbif_id": int(row.gbifID),
            }
            for row in merged.itertuples(index=False)
        }
        return map

    def match(self, guid: str) -> dict | None:
        """Matches a given GUID to a vernacular name."""
        return self.occurence_map.get(guid, None)
