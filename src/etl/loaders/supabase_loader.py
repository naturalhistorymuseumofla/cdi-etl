from datetime import datetime
from typing import Any, Dict, List, Optional

import pandas as pd
import requests

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
            {key: (None if pd.isna(value) else value) for key, value in row.items()}
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
            response = query.execute()
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
        chunk_size: int = 1000,
    ) -> None:
        """
        Synchronize a many-to-many join table based on a DataFrame of desired relationships.

        Args:
            join_table: Name of the join table to sync
            join_df: DataFrame containing the desired relationships with two columns:
                    one for source IDs and one for target IDs
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

        # Get unique source IDs from the DataFrame
        source_ids = join_df[source_key].unique()

        # Get only the relations that match our source IDs, using pagination
        print("\nRetrieving matching relations from database...")
        print(f"Filtering for {len(source_ids):,} source IDs")
        existing_joins = []
        page_size = 1000  # Keep pagination size at 1000
        source_chunk_size = (
            100  # Use smaller chunks for source IDs to avoid URL length limits
        )
        total_removed = 0

        # Process source IDs in smaller chunks to avoid URL length limits
        for i in range(0, len(source_ids), source_chunk_size):
            source_id_chunk = source_ids[i : i + source_chunk_size]
            chunk_joins = []
            page = 0

            while True:
                # Calculate offset for pagination
                offset = page * page_size

                # Fetch next page of matching relations for this chunk of source IDs
                response = (
                    self.client.table(join_table)
                    .select("*")
                    .in_(
                        source_key, list(source_id_chunk)
                    )  # Ensure consistent ordering
                    .limit(page_size)
                    .offset(offset)
                    .execute()
                )

                # Get data and check if we got any records
                batch = response.data
                if not batch:
                    break

                # Add records to our chunk collection
                chunk_joins.extend(batch)

                # Move to next page
                page += 1

                # If we got less than a full page, we're done with this chunk
                if len(batch) < page_size:
                    break

            # Add all relations from this chunk to main collection
            existing_joins.extend(chunk_joins)

        print(f"\nFinished retrieving {len(existing_joins):,} total relations")
        source_id_counts = join_df[source_key].value_counts()
        print(source_id_counts.head())

        # Build sets for comparison
        desired_relations = {
            (row[source_key], row[target_key]) for _, row in join_df.iterrows()
        }
        existing_relations = {
            (record[source_key], record[target_key]) for record in existing_joins
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
                self.client.table(join_table).upsert(
                    json=chunk,
                    on_conflict=f"{source_key},{target_key}",
                ).execute()

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
                    except requests.exceptions.RequestException:
                        # Fall back to individual deletes if the URL is too long
                        for target_id in chunk:
                            self.client.table(join_table).delete().eq(
                                source_key, source_id
                            ).eq(target_key, target_id).execute()
                            total_removed += 1

        # Calculate actual final count
        initial_count = len(existing_relations)
        final_count = initial_count - len(relations_to_remove) + len(relations_to_add)

        # Print summary
        print(f"\nJoin table sync summary for {join_table}:")
        print(f" Initial relations: {initial_count:,}")
        print(f" Source records processed: {len(source_ids):,}")
        print(f" Relations added: {len(relations_to_add):,}")
        print(f" Relations removed: {total_removed:,}")
        print(f" Final relations: {final_count:,}")

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
