from pyairtable import Table

from config.settings import settings


def fetch_data_from_airtable(table_name: str) -> list[dict]:
    """
    Fetch records from a specified Airtable table.

    Args:
        table_name (str): The name of the Airtable table to fetch data from.
    Returns:
        list[dict]: A list of records from the Airtable table.
    Raises:
        RuntimeError: If Airtable credentials are missing from config settings.
    """

    # Connect to Airtable using settings from config
    api_key = settings.airtable_pat
    base_id = settings.airtable_base_id

    if not api_key or not base_id:
        raise RuntimeError(
            "Airtable credentials missing: set AIRTABLE_PAT and AIRTABLE_BASE_ID in environment or .env"
        )

    table = Table(api_key, base_id, table_name)
    return table.all()
