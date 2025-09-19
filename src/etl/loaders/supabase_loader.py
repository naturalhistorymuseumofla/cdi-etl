from collections import Counter
from datetime import datetime
from typing import Any, Dict, List, Optional

import pandas as pd

from config.settings import settings
from supabase import Client, create_client


class SupabaseLoader:
    """Handles loading data into Supabase tables."""

    def __init__(
        self, url: Optional[str] = None, key: Optional[str] = None, timeout: int = 600
    ) -> None:
        """
        Initialize Supabase client.

        Args:
            url: Supabase project URL. Defaults to settings.supabase_url
            key: Supabase service role key. Defaults to settings.supabase_key
            timeout: Request timeout in seconds. Defaults to 600 (10 minutes)
        """
        self.url = url or settings.supabase_url
        self.key = key or settings.supabase_key

        if not self.url or not self.key:
            raise ValueError(
                "Supabase credentials missing. Set SUPABASE_URL and SUPABASE_KEY in .env"
            )

        self.client = create_client(self.url, self.key)

    def _validate_irn(self, rows: List[Dict[Any, Any]]) -> None:
        """
        Validate that each record has an irn field.

        Args:
            rows: List of records to validate

        Raises:
            ValueError: If any record is missing an irn or has an empty/null irn

        """
        for i, row in enumerate(rows):
            if "irn" not in row or not row["irn"]:
                raise ValueError(
                    f"Record at index {i} is missing required 'irn' field: {row}"
                )

    def _count_updates(self, responses: List[Dict[str, Any]]) -> dict:
        """
        Count number of inserted and updated records based on created_at and updated_at fields.
        Args:
            responses: List of response records from Supabase insert/upsert operation
        Returns:
            Dictionary with counts of 'inserted' and 'updated' records
        """
        operations = {"inserted": 0, "updated": 0}
        for record in responses:
            created = datetime.fromisoformat(record["created_at"])
            updated = datetime.fromisoformat(record["updated_at"])

            if created == updated:
                operations["inserted"] += 1
            else:
                operations["updated"] += 1
        return operations

    def insert_rows(
        self,
        table_name: str,
        rows: List[Dict[Any, Any]],
        upsert: bool = False,
        chunk_size: int = 1000,
    ) -> list:
        """
        Insert rows into a Supabase table.

        Args:
            table_name: Name of the table to insert into
            rows: List of row dictionaries to insert (must contain 'irn' field)
            upsert: If True, performs an upsert operation. Defaults to False
            chunk_size: Number of rows to insert in each batch. Defaults to 1000

        Returns:
            Dictionary with 'results' (list of inserted/updated records) and
            'operations' (counts of inserted and updated records)

        Raises:
            ValueError: If any record is missing the required 'irn' field
        """
        # Validate all rows have irn before processing
        self._validate_irn(rows)

        results = []
        for i in range(0, len(rows), chunk_size):
            chunk = rows[i : i + chunk_size]
            query = self.client.table(table_name).insert(chunk)
            if upsert:
                # Use irn as the conflict detection column
                query = self.client.table(table_name).upsert(
                    on_conflict="irn", json=chunk
                )
            response = query.execute()
            results.extend(response.data)

        operations = self._count_updates(results)
        # Optionally log or handle operations here if needed

        return [results, operations]

    def load_dataframe(
        self,
        table_name: str,
        df: pd.DataFrame,
        upsert: bool = False,
        chunk_size: int = 1000,
    ) -> list:
        """
        Load a pandas DataFrame into a Supabase table.

        Args:
            table_name: Name of the table to insert into
            df: pandas DataFrame to load (must contain 'irn' column)
            upsert: If True, performs an upsert operation. Defaults to False
            chunk_size: Number of rows to insert in each batch. Defaults to 1000

        Returns:
            Dictionary with 'results' (list of inserted/updated records) and
            'operations' (counts of inserted and updated records)

        Raises:
            ValueError: If DataFrame is missing the required 'irn' column
        """
        if "irn" not in df.columns:
            raise ValueError("DataFrame must contain 'irn' column")

        # Check for null/empty irns
        null_irns = df["irn"].isna().sum()
        if null_irns > 0:
            raise ValueError(f"Found {null_irns} rows with null/empty irn values")

        rows = df.to_dict("records")
        return self.insert_rows(table_name, rows, upsert, chunk_size)


# Usage example:
if __name__ == "__main__":
    loader = SupabaseLoader()

    # Insert individual rows
    rows = [{"name": "Test 1", "value": 100}, {"name": "Test 2", "value": 200}]
    results = loader.insert_rows("test_table", rows)

    # Load from DataFrame
    df = pd.DataFrame(rows)
    results = loader.load_dataframe("test_table", df)
