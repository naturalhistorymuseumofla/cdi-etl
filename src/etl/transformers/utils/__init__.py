from typing import Iterable, List


def flatten_field(field: Iterable[List[dict]], field_name: str) -> List[List[str]]:
    """
    Extracts the values for a given field name from a nested list of dictionaries.

    Args:
        field: A list of lists, where each inner list contains dictionaries.
        field_name: The key to extract from each dictionary.

    Returns:
        A nested list of strings, where each inner list contains the extracted values for the specified field name.
    """
    return [[d[field_name] for d in sublist] for sublist in field]


def to_pg_array(py_list):
    """Convert a Python list to a PostgreSQL array string for CSV export."""
    if not isinstance(py_list, list) or not py_list:
        return "{}"
    return "{" + ",".join('"' + str(x).replace('"', '\\"') + '"' for x in py_list) + "}"


__all__ = ["flatten_field", "to_pg_array"]
