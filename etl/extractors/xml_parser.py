import re
import xml.etree.ElementTree as ET
from typing import Any, Dict, List


def extract_schema_from_pi(xml_file: str) -> str:
    """
    Extracts the schema block from an XML file's processing instruction.

    Args:
        xml_file: Path to the XML file.

    Returns:
        The schema text as a string.

    Raises:
        ValueError: If no schema block is found in the XML.
    """
    with open(xml_file, "r", encoding="utf-8") as f:
        xml_text = f.read()
    match = re.search(r"<\?schema(.*?)\?>", xml_text, re.DOTALL)
    if not match:
        raise ValueError("No schema block found in XML processing instructions.")
    return match.group(1)


def parse_schema(schema_text: str) -> Dict[str, Any]:
    """
    Parses the schema text and returns a dictionary describing the expected fields and nested tables/tuples.

    Args:
        schema_text: The schema block as a string.

    Returns:
        A dictionary mapping field/table/tuple names to their type or structure.
        - 'field' for atom fields
        - {'fields': [...]} for nested tables/tuples with multiple fields
        - {'single': fieldname} for nested tables/tuples with a single field
    """
    lines = [line.strip() for line in schema_text.splitlines() if line.strip()]
    stack = []
    schema = {}
    current_table = None
    fields = []
    for line in lines:
        if line.startswith("table") or line.startswith("tuple"):
            block_type, block_name = line.split()[:2]
            stack.append((fields, current_table))
            fields = []
            current_table = block_name
        elif line == "end":
            # Handle both table and tuple blocks
            if len(fields) == 1:
                schema[current_table] = {"single": fields[0]}
            else:
                schema[current_table] = {"fields": fields.copy()}
            fields, current_table = stack.pop()
        else:
            parts = line.split()
            if len(parts) >= 2:
                field_name = parts[-1]
                fields.append(field_name)
    for field in fields:
        schema[field] = "field"
    return schema


def parse_tuple(elem, schema, is_top_level=False):
    """
    Recursively parses a <tuple> XML element according to the schema.

    Args:
        elem: The XML element to parse.
        schema: The schema dictionary for the current level.
        is_top_level: Whether this is the top-level tuple (to avoid including the top-level table name).

    Returns:
        A dictionary representing the parsed record, with all expected fields/tables present.
    """
    data = {}
    for child in elem:
        if child.tag == "atom":
            value = (child.text or "").strip()
            data[child.attrib["name"]] = value

        # <table name="..."> ... <tuple> ... </tuple> ... </table>
        elif child.tag == "table":
            table_name = child.attrib["name"]
            table_schema = schema.get(table_name)
            nested_rows = [
                parse_tuple(
                    subtuple, table_schema if table_schema else {}, is_top_level=False
                )
                for subtuple in child.findall("tuple")
            ]
            if table_schema:
                if "single" in table_schema:
                    nested_rows = [
                        row.get(table_schema["single"], "") for row in nested_rows
                    ]
                elif "fields" in table_schema:
                    for row in nested_rows:
                        for field in table_schema["fields"]:
                            row.setdefault(field, "")
            data[table_name] = nested_rows

        # Handle schema-declared "tuple" blocks that appear directly as a child
        # e.g. <tuple name="AntSiteRef"> ... </tuple>
        elif child.tag == "tuple":
            tuple_name = child.attrib.get("name")
            if tuple_name:
                tuple_schema = schema.get(tuple_name)
                nested = parse_tuple(
                    child, tuple_schema if tuple_schema else {}, is_top_level=False
                )
                # store as list (consistent with <table> handling)
                if tuple_schema and "single" in tuple_schema:
                    # single-field tuple -> list[str]
                    data[tuple_name] = [nested.get(tuple_schema["single"], "")]
                else:
                    # multi-field tuple -> list[dict]
                    # ensure fields present
                    if tuple_schema and "fields" in tuple_schema:
                        for field in tuple_schema["fields"]:
                            nested.setdefault(field, "")
                    data[tuple_name] = [nested]
            else:
                # unnamed tuple: merge its atoms into current level (fallback)
                nested = parse_tuple(child, {}, is_top_level=False)
                data.update(nested)

    # Ensure expected fields/tables are present per schema
    for key, val in schema.items():
        if key not in data:
            if val == "field":
                data[key] = ""
            elif isinstance(val, dict) and "fields" in val:
                data[key] = [{field: "" for field in val["fields"]}]
            elif isinstance(val, dict) and "single" in val:
                data[key] = []

    # If parsing top-level ecatalogue, remove the wrapper keys that are not actual fields
    if is_top_level and "fields" in schema:
        for key in list(data.keys()):
            if key not in schema["fields"] and key not in schema:
                del data[key]

    return data


def xml_to_json(xml_file: str) -> List[Dict[str, Any]]:
    """
    Converts an EMu XML file to a list of dictionaries, one per record.

    Args:
        xml_file: Path to the EMu XML file.

    Returns:
        A list of dictionaries, each representing a record with all expected fields and nested tables.
        - Atom fields are strings.
        - Multi-field tables are lists of dicts.
        - Single-field tables are lists of strings.
        - Missing fields/tables are filled with "" or [] as appropriate.
    """
    schema_text = extract_schema_from_pi(xml_file)
    schema = parse_schema(schema_text)
    module = "ecatalogue" if schema.get("ecatalogue") else "etaxonomy"
    tree = ET.parse(xml_file)
    root = tree.getroot()
    rows = []
    for tuple_elem in root.findall("tuple"):
        row = parse_tuple(tuple_elem, schema[module])
        rows.append(row)
    return rows
