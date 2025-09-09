import re
import unicodedata
from csv import DictReader
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
            self.table = self._fetch_airtable_data()
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
        return table

    def airtable_to_dataframe(self) -> pd.DataFrame:
        """Fetches all records from the given Airtable table and converts them to a DataFrame."""
        records = self.table.all()
        cultures = pd.DataFrame([record["fields"] for record in records]).fillna("")
        cultures["record_id"] = [record["id"] for record in records]
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
            "record_id",
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
        term = (
            term.strip()
            .replace('"', "")
            .replace("possibly ", "")
            .replace("?", "")
            .replace("probably ", "")
            .replace(" style", "")
            .strip()
        )

        # Find text inside parentheses (e.g. "(A, B or C)") and capture each group's contents.
        parentheticals = re.findall(r"\(([^)]+)\)", term)

        terms = []
        # Process each parenthetical group: split on commas, slashes or the word " or ",
        # strip whitespace and collect non-empty tokens.
        for group in parentheticals:
            for sub in re.split(r"[,/]| or ", group):
                sub = sub.strip()
                if sub:
                    terms.append(sub)

        # Remove the parenthetical portions from the original string so we can parse
        # the "main" part (outside parentheses) separately.
        main = re.sub(r"\([^)]+\)", "", term)

        # Split the remaining main string on common separators (comma, slash, space-dash-space)
        # and the word " or ". We intentionally only split on a spaced dash (` - `)
        # to preserve hyphenated names like "Jama-Coaque".
        for part in re.split(r",|/| - | or |; ", main):
            part = part.strip()
            if part:
                terms.append(part)

        # Normalize: remove diacritics, lower-case, remove empty entries and deduplicate.
        # Use Unicode NFKD decomposition and drop combining marks so e.g. 'Apinajé' -> 'Apinaje'.
        def _strip_diacritics(s: str) -> str:
            nkfd = unicodedata.normalize("NFKD", s)
            return "".join(ch for ch in nkfd if not unicodedata.combining(ch))

        normalized = {(_strip_diacritics(t).lower()) for t in terms if t}
        return list(normalized)

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
            id = str(row["id"]).strip()
            parent = row.get("parent_culture")
            if id and pd.notnull(parent) and str(parent).strip():
                parent_lookup[id] = str(parent).strip()
        return parent_lookup

    def _get_all_parents(self, id: str) -> Set[int]:
        """
        Recursively collects all parent cultures for a given culture name.
        """
        parents = set()
        current = id
        while current in self.parent_lookup:
            parent = self.parent_lookup[current]
            if parent and parent not in parents:
                parents.add(parent)
                current = parent
            else:
                break
        return parents

    def match(self, motif: str) -> List[int]:
        """
        Matches a motif string to culture names, excluding any that are parents of other matched cultures.

        Args:
            motif: The motif term string.

        Returns:
            A list of matched culture names (children only, no parents).
        """
        if not motif:
            return []

        terms = self.extract_terms(motif)
        matched = set()
        for t in terms:
            id = self.name_id_lookup.get(t)
            if id is not None:
                matched.add(id)

        # Remove any culture that is a parent of another matched culture
        parents = set()
        for id in matched:
            parent = self.parent_lookup.get(id)
            if parent in matched:
                parents.add(parent)
        children_only = matched - parents

        return list(children_only)

    def get_id(self, name: str) -> int | None:
        """
        Returns the culture id for a given culture name, or None if not found.

        Args:
            name: The culture name.

        Returns:
            The culture id as an integer, or None if not found.
        """
        id = self.name_id_lookup.get(name.lower())
        if id is not None:
            try:
                return int(id)
            except ValueError:
                return None
        return None

    def match_list(self, motifs: List[str]) -> List[int]:
        """
        Matches a list of motif strings to culture names, excluding any that are parents of other matched cultures.

        Args:
            motifs: A list of motif term strings.

        Returns:
            A list of matched culture names (children only, no parents).
        """
        if not motifs:
            return []

        matched = set()
        for motif in motifs:
            matches = self.match(motif)
            matched.update(matches)
        parents = set()
        for name in matched:
            parent = self.parent_lookup.get(name)
            if parent in matched:
                parents.add(parent)
        children_only = matched - parents

        return list(children_only)

    def get_descendant_ids(self, parent_id: int | str) -> List[int]:
        """
        Return all descendant culture IDs (children, grandchildren, etc.) for the given parent ID.

        Args:
            parent_id: parent culture id (int or str)

        Returns:
            List[int] of descendant culture ids. Non-integer ids are skipped.
        """
        # Normalize parent id to string because lookups are stored as strings
        parent_key = str(parent_id)

        # Build parent -> set(children) mapping from self.parent_lookup_id (child -> parent)
        parent_to_children: Dict[str, Set[str]] = {}
        for child_id, par_id in self.parent_lookup_id.items():
            if not par_id:
                continue
            parent_to_children.setdefault(str(par_id), set()).add(str(child_id))

        # Traverse breadth-first/stack to collect all descendants
        descendants: Set[str] = set()
        stack = list(parent_to_children.get(parent_key, []))
        while stack:
            cid = stack.pop()
            if cid in descendants:
                continue
            descendants.add(cid)
            # enqueue this child's children
            for grandchild in parent_to_children.get(cid, []):
                if grandchild not in descendants:
                    stack.append(grandchild)

        # Convert to ints where possible, skip non-integer ids
        out: List[int] = []
        for cid in descendants:
            try:
                out.append(int(cid))
            except (ValueError, TypeError):
                # skip ids that can't be converted to int
                continue

        return out

    def update_record(self, record_id: str, fields: Dict) -> Dict:
        """
        Update a record in the Airtable table.

        Args:
            record_id: The Airtable record ID to update.
            fields: A dictionary of fields to update.

        Returns:
            The updated record as a dictionary.
        """
        if not self.table:
            raise RuntimeError("Airtable table is not initialized.")

        updated_record = self.table.update(record_id, fields)
        return updated_record  # type: ignore

    def get_culture_by_id(self, id: int | str) -> Dict | None:
        """
        Returns the culture record for a given culture id, or None if not found.

        Args:
            id: The culture id.

        Returns:
            The culture record as a dictionary, or None if not found.
        """
        if not self.cultures.empty:
            record = self.cultures[self.cultures["id"] == id]
            if not record.empty:
                return record.iloc[0].to_dict()
            else:
                return None
        return None

    def get_name_by_id(self, id: int | str) -> str:
        """
        Returns the culture name for a given culture id, or None if not found.

        Args:
            id: The culture id.

        Returns:
            The culture name as a string, or None if not found.
        """
        if type(id) is str:
            id = int(id)
        if not self.cultures.empty:
            record = self.cultures[self.cultures["id"] == id]
            if not record.empty:
                return record.iloc[0]["name"]
            else:
                return ""
        return ""
