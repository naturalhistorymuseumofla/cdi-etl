import re
from typing import Dict, List, Set

import pandas as pd


class CultureMatcher:
    """
    Matches motif strings to culture names and their parents using a lookup built from a cultures DataFrame.
    """

    def __init__(self, cultures: pd.DataFrame):
        """
        Initializes the matcher and builds the lookup dictionaries.

        Args:
            cultures: A DataFrame with 'name', 'endonyms', and 'parent_culture' columns.
        """
        self.culture_lookup = self._build_culture_lookup(cultures)
        self.parent_lookup = self._build_parent_lookup(cultures)

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
        return list(children_only)
