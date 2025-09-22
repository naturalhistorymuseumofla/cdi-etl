"""
Reads EMu data from csv into a DataFrame

To import:
    >>> from emu import emu
"""

import pandas as pd


def read_csv(file_path: str) -> pd.DataFrame:
    """Reads a CSV file and returns a DataFrame."""
    return pd.read_csv(
        file_path,
        keep_default_na=False,
        engine="pyarrow",
        on_bad_lines="warn",
        parse_dates=False,  # Prevent automatic date parsing
    )
