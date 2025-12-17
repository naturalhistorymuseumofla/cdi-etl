"""
Reads EMu data from csv into a DataFrame

To import:
    >>> from emu import emu
"""

import pandas as pd


def read_csv(
    file_path: str,
    delimiter: str = ",",
    compression: str = None,
    columns: list[str] = None,
    dtype: dict = None,
) -> pd.DataFrame:
    """Reads a CSV file and returns a DataFrame."""
    return pd.read_csv(
        file_path,
        keep_default_na=False,
        on_bad_lines="skip",
        parse_dates=False,  # Prevent automatic date parsing
        delimiter=delimiter,
        compression=compression,
        usecols=columns,
        low_memory=False,
        dtype=dtype,
    )
