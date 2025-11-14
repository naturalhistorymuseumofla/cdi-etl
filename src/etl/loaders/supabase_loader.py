from datetime import datetime
from typing import Any, Dict, List, Optional
import json
import pandas as pd

from config.settings import settings
from supabase import create_client


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

    def _validate_primary_key(
        self, rows: List[Dict[Any, Any]], primary_key: Optional[str] = None
    ) -> None:
        """
        Validate that each record has the specified primary key field if one is required.

        Args:
            rows: List of records to validate
            primary_key: Name of the primary key field to validate. If None, no validation is performed.

        Raises:
            ValueError: If any record is missing the primary key or has an empty/null value
        """
        if not primary_key:
            return

        for i, row in enumerate(rows):
            if primary_key not in row or not row[primary_key]:
                raise ValueError(
                    f"Record at index {i} is missing required '{primary_key}' field: {row}"
                )

    def _replace_nan_with_none(self, value):
        """
        Recursively replace NaN values with None in lists, dictionaries, or individual values.
        """
        if isinstance(value, list):  # If the value is a list, process each element
            return [self._replace_nan_with_none(v) for v in value]
        if pd.isna(value):  # Check for NaN
            return None
        if isinstance(
            value, dict
        ):  # If the value is a dictionary, process each key-value pair
            return {k: self._replace_nan_with_none(v) for k, v in value.items()}
        return value  # Return the value as-is if it's not NaN, a list, or a dictionary

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
        primary_key: Optional[str] = None,
        upsert: bool = False,
        chunk_size: int = 1000,
    ) -> list:
        """
        Insert rows into a Supabase table.

        Args:
            table_name: Name of the table to insert into
            rows: List of row dictionaries to insert
            primary_key: Name of the primary key field for validation and upsert operations.
                       If None, no primary key validation is performed.
                       For backwards compatibility, defaults to 'irn' if upsert is True.
            upsert: If True, performs an upsert operation. Defaults to False
            chunk_size: Number of rows to insert in each batch. Defaults to 1000

        Returns:
            Dictionary with 'results' (list of inserted/updated records) and
            'operations' (counts of inserted and updated records)

        Raises:
            ValueError: If any record is missing the required primary key field
        """
        # For backwards compatibility, use 'irn' as primary key if upsert is True and no key specified
        if upsert and primary_key is None:
            primary_key = "irn"

        # Validate primary key if specified
        self._validate_primary_key(rows, primary_key)

        # Replace NaN values with None in all rows

        rows = [
            {key: self._replace_nan_with_none(value) for key, value in row.items()}
            for row in rows
        ]

        results = []
        for i in range(0, len(rows), chunk_size):
            chunk = rows[i : i + chunk_size]
            query = self.client.table(table_name).insert(chunk)
            if upsert and primary_key:
                # Use specified primary key as conflict detection column
                query = self.client.table(table_name).upsert(
                    on_conflict=primary_key, json=chunk
                )
            try:
                response = query.execute()
            except Exception as e:
                # Print helpful context before re-raising so you can see failing payload
                print(
                    f"\nSupabase API error when inserting to '{table_name}' (upsert={upsert}, primary_key={primary_key})"
                )
                print(f"Chunk index start={i} size={len(chunk)}. Sample payload:")
                try:
                    print(json.dumps(chunk[:3], default=str, indent=2))
                except Exception:
                    print(chunk[:3])
                raise e
            results.extend(response.data)

        operations = self._count_updates(results)
        # Optionally log or handle operations here if needed

        self.print_load_summary(
            table_name, {"operations": operations, "results": results}
        )

        return [results, operations]

    def load_dataframe(
        self,
        table_name: str,
        df: pd.DataFrame,
        primary_key: Optional[str] = None,
        upsert: bool = False,
        chunk_size: int = 1000,
    ) -> list:
        """
        Load a pandas DataFrame into a Supabase table.

        Args:
            table_name: Name of the table to insert into
            df: pandas DataFrame to load
            primary_key: Name of the primary key column for validation and upsert operations.
                       If None, no primary key validation is performed.
                       For backwards compatibility, defaults to 'irn' if upsert is True.
            upsert: If True, performs an upsert operation. Defaults to False
            chunk_size: Number of rows to insert in each batch. Defaults to 1000

        Returns:
            Dictionary with 'results' (list of inserted/updated records) and
            'operations' (counts of inserted and updated records)

        Raises:
            ValueError: If DataFrame is missing the required primary key column
        """
        # For backwards compatibility, use 'irn' as primary key if upsert is True and no key specified
        if upsert and primary_key is None:
            primary_key = "irn"

        # Validate primary key if specified
        if primary_key:
            if primary_key not in df.columns:
                raise ValueError(f"DataFrame must contain '{primary_key}' column")

            # Check for null/empty values in primary key
            null_keys = df[primary_key].isna().sum()
            if null_keys > 0:
                raise ValueError(
                    f"Found {null_keys:,} rows with null/empty {primary_key} values"
                )

        rows = df.to_dict("records")
        return self.insert_rows(
            table_name,
            rows,
            primary_key=primary_key,
            upsert=upsert,
            chunk_size=chunk_size,
        )

    def sync_join_table(
        self,
        join_table: str,
        join_df: pd.DataFrame,
        source_key: str,
        target_key: str,
        chunk_size: int = 100,
        keys_unique: bool = True,
    ) -> None:
        """
        Synchronize a join table based on a DataFrame of desired relationships.

        Args:
            join_table: Name of the join table to sync
            join_df: DataFrame containing the desired relationships with two columns:
            source_key: Name of the source ID column in both join_df and join_table
            target_key: Name of the target ID column in both join_df and join_table
            chunk_size: Number of rows to process in each batch

        Example:
            # DataFrame with desired relationships
            join_df = pd.DataFrame({
                'catalogue_irn': [1, 1, 2],
                'culture_id': ['A', 'B', 'A']
            })

            loader.sync_join_table(
                join_table='anthropology_catalogue_cultures',
                join_df=join_df,
                source_key='catalogue_irn',
                target_key='culture_id'
            )
        """
        # Remove any null values
        join_df = join_df.dropna(subset=[source_key, target_key])

        # Fetch existing rows from the table
        print(f"\nFetching existing rows from {join_table}...")
        existing_rows = []
        page_size = chunk_size  # Number of rows to fetch per request
        source_ids = join_df[source_key].unique().tolist()

        # Process source IDs in chunks to avoid overly long queries
        for i in range(0, len(source_ids), chunk_size):
            source_id_chunk = source_ids[i : i + chunk_size]
            response = (
                self.client.table(join_table)
                .select(f"{source_key},{target_key}")
                .in_(source_key, source_id_chunk)  # Filter rows by source_key
                .limit(page_size)
                .execute()
            )

            batch = response.data
            if batch:
                existing_rows.extend(batch)

        print(f"Fetched {len(existing_rows):,} existing rows.")

        # Build sets for comparison
        desired_relations = {
            (int(row[source_key]), int(row[target_key]))
            for _, row in join_df.iterrows()
        }
        existing_relations = {
            (int(row[source_key]), int(row[target_key])) for row in existing_rows
        }

        # Calculate differences
        relations_to_add = desired_relations - existing_relations
        relations_to_remove = existing_relations - desired_relations

        # Add new relations in batches using upsert to handle duplicates
        if relations_to_add:
            new_records = [
                {source_key: source_id, target_key: target_id}
                for source_id, target_id in relations_to_add
            ]

            for i in range(0, len(new_records), chunk_size):
                chunk = new_records[i : i + chunk_size]
                # Use RPC call to handle upsert properly
                if keys_unique:
                    self.client.table(join_table).upsert(
                        json=chunk,
                        on_conflict=f"{source_key},{target_key}",
                    ).execute()
                else:
                    self.client.table(join_table).upsert(json=chunk).execute()

        # Remove old relations in batches, grouping by source_id to minimize API calls
        if relations_to_remove:
            # Group relations to remove by source_id
            relations_by_source = {}
            for source_id, target_id in relations_to_remove:
                if source_id not in relations_by_source:
                    relations_by_source[source_id] = set()
                relations_by_source[source_id].add(target_id)

            # Process each source_id's relations in a single delete call where possible
            total_removed = 0
            for source_id, target_ids in relations_by_source.items():
                target_id_chunks = list(target_ids)
                for i in range(0, len(target_id_chunks), chunk_size):
                    chunk = target_id_chunks[i : i + chunk_size]
                    try:
                        # Try batch delete first
                        self.client.table(join_table).delete().eq(
                            source_key, source_id
                        ).in_(target_key, chunk).execute()
                        total_removed += len(chunk)
                    except Exception:
                        # Fall back to individual deletes if the URL is too long
                        for target_id in chunk:
                            self.client.table(join_table).delete().eq(
                                source_key, source_id
                            ).eq(target_key, target_id).execute()
                            total_removed += 1

        print(f"Synchronization complete for {join_table}.")

    def print_load_summary(self, table_name: str, summary: dict) -> None:
        """
        Print a summary of the load operation.

        Args:
            table_name: Name of the table that was loaded
            operations: Dictionary with counts of 'inserted' and 'updated' records
        """
        operations = summary.get("operations", {})
        results = summary.get("results", [])
        print(f"\nProcessed {len(results):,} total records in {table_name}:")
        print(f" Inserted: {operations['inserted']:,}")
        print(f" Updated: {operations['updated']:,}")
