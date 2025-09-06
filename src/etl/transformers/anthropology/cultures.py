import re
from typing import Dict, List, Set

import pandas as pd
from pyairtable import Table

from config.settings import settings


class Cultures:
    """
    Matches motif strings to culture names and their parents using a lookup built from a cultures DataFrame.
    """

    def __init__(self, cultures: pd.DataFrame = pd.DataFrame()) -> None:
        """
        Initializes the matcher and builds the lookup dictionaries.

        Args:
            cultures: A DataFrame with 'name', 'endonyms', and 'parent_culture' columns.
        """

        if cultures.empty:
            self.cultures = self.airtable_to_dataframe()
            self.cultures = self.clean_culture_df(self.cultures)
        else:
            # assume caller provided a cleaned cultures DataFrame
            self.cultures = self.clean_culture_df(cultures)

        # Build lookups used for matching. We maintain both name->id and
        # parent relationships by id so we can produce join rows.
    self.name_id_lookup = self._build_name_id_lookup(self.cultures)
    self.parent_lookup_id = self._build_parent_lookup_ids(self.cultures)
    # Keep the original name-based lookups for backward compatibility
    self.culture_lookup = self._build_culture_lookup(self.cultures)
    self.parent_lookup = self._build_parent_lookup(self.cultures)

    @staticmethod
    def _fetch_airtable_data():
        """Connects to Airtable using settings from the config."""
        api_key = settings.airtable_pat
        base_id = settings.airtable_base_id

        if not api_key or not base_id:
            raise RuntimeError(
                "Airtable credentials missing: set AIRTABLE_PAT and AIRTABLE_BASE_ID in environment or .env"
            )

        table = Table(api_key, base_id, "Anthro Cultures")
        return table.all()

    def airtable_to_dataframe(self) -> pd.DataFrame:
        """Fetches all records from the given Airtable table and converts them to a DataFrame."""
        records = self._fetch_airtable_data()
        cultures = pd.DataFrame([record["fields"] for record in records]).fillna("")
        cultures["parent_culture"] = cultures["name (from parent_culture)"].apply(
            lambda x: x[0] if x else ""
        )
        cultures["synonyms"] = cultures["synonyms"].apply(lambda x: x if x else [])
        return cultures

    def clean_culture_df(self, cultures: pd.DataFrame) -> pd.DataFrame:
        """Cleans the culture DataFrame by filling NaNs and ensuring lists."""
        cultures = cultures.fillna("")
        cols = [
            "id",
            "name",
            "type",
            "region",
            "parent_id",
            "parent_culture",
            "age_start",
            "age_end",
            "synonyms",
            "endonyms",
            "aat_id",
            "wikidata_id",
            "aat_notes",
            "description",
        ]
        cultures = cultures[cols]
        return cultures

    def get_cultures_dataframe(self) -> pd.DataFrame:
        """Returns the cultures DataFrame used to build the lookups."""
        return self.cultures

    @staticmethod
    def extract_terms(term: str) -> List[str]:
        """
        Extracts all possible terms from a motif string, including those in parentheticals.
        """
        parentheticals = re.findall(r"\(([^)]+)\)", term)
        terms = []
        for group in parentheticals:
            for sub in re.split(r"[,/]| or ", group):
                sub = sub.strip()
                if sub:
                    terms.append(sub)
        main = re.sub(r"\([^)]+\)", "", term)
        for part in re.split(r"[,/-]| or ", main):
            part = part.strip()
            if part:
                terms.append(part)
        return list({t.lower() for t in terms if t})

    @staticmethod
    def _build_culture_lookup(cultures: pd.DataFrame) -> Dict[str, str]:
        """
        Builds a lookup dictionary mapping all possible names and endonyms to the main culture name.
        """
        lookup = {}
        for _, row in cultures.iterrows():
            main_name = str(row["name"]).strip()
            if main_name:
                lookup[main_name.lower()] = main_name
            synonyms = row.get("synonyms")
            if synonyms:
                for synonym in synonyms:
                    synonym = synonym.strip()
                    if synonym:
                        lookup[synonym.lower()] = main_name

        return lookup

    @staticmethod
    def _build_name_id_lookup(cultures: pd.DataFrame) -> Dict[str, str]:
        """Build a lookup mapping lowercased names and synonyms to the culture id."""
        lookup: Dict[str, str] = {}
        for _, row in cultures.iterrows():
            main_name = str(row.get("name", "")).strip()
            cid = row.get("id")
            if pd.isna(cid) or cid == "":
                continue
            cid = str(cid)
            if main_name:
                lookup[main_name.lower()] = cid
            synonyms = row.get("synonyms")
            if synonyms:
                for synonym in synonyms:
                    syn = str(synonym).strip()
                    if syn:
                        lookup[syn.lower()] = cid
        return lookup

    @staticmethod
    def _build_parent_lookup_ids(cultures: pd.DataFrame) -> Dict[str, str]:
        """Build a mapping from child id -> parent id (both as strings) where available."""
        parent_lookup: Dict[str, str] = {}
        for _, row in cultures.iterrows():
            cid = row.get("id")
            if pd.isna(cid) or cid == "":
                continue
            cid = str(cid)
            parent_id = row.get("parent_id")
            # parent_id may be a list or a single value; handle common cases
            if isinstance(parent_id, list) and parent_id:
                parent = str(parent_id[0]).strip()
            else:
                parent = str(parent_id).strip() if parent_id not in (None, "") else ""
            if parent:
                parent_lookup[cid] = parent
        return parent_lookup

    @staticmethod
    def _build_parent_lookup(cultures: pd.DataFrame) -> Dict[str, str]:
        """
        Builds a lookup dictionary mapping each culture name to its parent culture name.
        """
        parent_lookup = {}
        for _, row in cultures.iterrows():
            name = str(row["name"]).strip()
            parent = row.get("parent_culture")
            if name and pd.notnull(parent) and str(parent).strip():
                parent_lookup[name] = str(parent).strip()
        return parent_lookup

    def _get_all_parents(self, name: str) -> Set[str]:
        """
        Recursively collects all parent cultures for a given culture name.
        """
        parents = set()
        current = name
        while current in self.parent_lookup:
            parent = self.parent_lookup[current]
            if parent and parent not in parents:
                parents.add(parent)
                current = parent
            else:
                break
        return parents

    def match(self, motif: str) -> List[str]:
        """
        Matches a motif string to culture names, excluding any that are parents of other matched cultures.

        Args:
            motif: The motif term string.

        Returns:
            A list of matched culture names (children only, no parents).
        """
        terms = self.extract_terms(motif)
        matched = set()
        for t in terms:
            name = self.culture_lookup.get(t)
            if name is not None:
                matched.add(name)

        # Remove any culture that is a parent of another matched culture
        parents = set()
        for name in matched:
            parent = self.parent_lookup.get(name)
            if parent in matched:
                parents.add(parent)
        children_only = matched - parents

        return list(children_only)

    def match_list_ids(self, motifs: List[str]) -> List[str]:
        """
        Match a list of motif strings to culture ids (not names). Returns a list of
        culture ids (strings) with parent ids removed when a child is present.
        """
        matched_ids: Set[str] = set()
        for motif in motifs:
            terms = self.extract_terms(motif)
            for t in terms:
                cid = self.name_id_lookup.get(t)
                if cid is not None:
                    matched_ids.add(cid)

        # Remove any culture id that is a parent of another matched culture id
        parents = set()
        for cid in list(matched_ids):
            parent = self.parent_lookup_id.get(cid)
            if parent in matched_ids:
                parents.add(parent)
        children_only = matched_ids - parents
        return list(children_only)

    def match_list(self, motifs: List[str]) -> List[str]:
        """
        Matches a list of motif strings to culture names, excluding any that are parents of other matched cultures.

        Args:
            motifs: A list of motif term strings.

        Returns:
            A list of matched culture names (children only, no parents).
        """
        matched = set()
        for motif in motifs:
            terms = self.extract_terms(motif)
            for t in terms:
                name = self.culture_lookup.get(t)
                if name is not None:
                    matched.add(name)

        # Remove any culture that is a parent of another matched culture
        parents = set()
        for name in matched:
            parent = self.parent_lookup.get(name)
            if parent in matched:
                parents.add(parent)
        children_only = matched - parents
        return list(children_only)
