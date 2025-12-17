import pandas as pd
import inflect


class GbifMatcher:
    """Class to match vernacular names from GBIF to internal taxonomy IDs."""

    def __init__(
        self,
        vernaculars: pd.DataFrame,
        occurences: pd.DataFrame,
    ):
        self.inflection_engine = inflect.engine()
        self.vernaculars = vernaculars
        self.occurences = occurences
        self._assign_source_weight()
        self.occurence_map = self._create_occurence_vernacular_map()
        self.canonical_name_map = self._create_canonical_name_vernacular_map()

    def _assign_source_weight(self):
        weights = {
            "IOC World Bird List, v13.2": 5,
            "The Paleobiology Database": 4,
            "Checklist of Vermont Species": 3,
            "Martha's Vineyard species checklist": 3,
            "Multilingual IOC World Bird List, v11.2": 2,
            "Catalogue of Life Checklist": 2,
            "The IUCN Red List of Threatened Species": 1,
        }
        self.vernaculars["source_weight"] = self.vernaculars["source"].apply(
            lambda x: weights.get(x, 0)
        )

    def _create_occurence_vernacular_map(self) -> dict:
        """Creates a mapping from occurrence IDs to vernacular names."""

        # Convert taxonKey

        # Merge occurences with vernacular names on taxonKey and taxonID
        merged = pd.merge(
            self.occurences,
            self.vernaculars,
            left_on="taxonKey",
            right_on="taxonID",
            how="left",
        ).dropna(subset=["vernacularName"])

        # Assign weights to sources for prioritization
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

    def _create_canonical_name_vernacular_map(self) -> dict:
        """Creates a mapping from canonical names to vernacular names."""

        # Sort vernaculars by source weight and drop duplicates on canonicalName
        vernaculars = self.vernaculars.sort_values(
            by=["source_weight"], ascending=False
        ).drop_duplicates(subset=["canonicalName"], keep="first")

        map = {
            row.canonicalName: {
                "vernacular_name": row.vernacularName,
                "source": row.source,
            }
            for row in vernaculars.itertuples(index=False)
        }
        return map

    def match(self, guid: str) -> dict | None:
        """Matches a given GUID to a vernacular name."""
        return self.occurence_map.get(guid, None)

    def match_canonical_name(self, canonical_name: str) -> dict | None:
        """Matches a given canonical name to a vernacular name."""
        return self.canonical_name_map.get(canonical_name, None)
