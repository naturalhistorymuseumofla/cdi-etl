"""Tests for the CSV parser.

This module writes a small slice of a real EMu CSV export to a temporary
file and asserts that `etl.extractors.csv_parser.read_csv` returns a
pandas DataFrame with expected columns and values.
"""

import pandas as pd

from etl.extractors import csv_parser

SAMPLE_CSV = """"operation","date_emu_record_modified","irn","emu_guid","department","catalogue_number","type_status","sex","life_stage","side","element_group","element","locality","locality_irn","taxon_irn"
"UPDATE","2024-06-18","2677267","87222519-211c-4d03-90a3-ca3c76dd10a7","Dinosaur Institute","LACM-DI 161292","","","","","","Indet.  14-N-4","DILACM7683 : LACM 7683 : Shumway Point East : Morrison : Brushy Basin : San Juan : Utah : USA : Kimmeridgian","916190","8818"
"UPDATE","2023-04-07","2677958","eeded059-fc9e-4d5c-980c-3e26bf2b9b98","Dinosaur Institute","LACM-DI 161276","","","","L","","scapula cast","DILACM8148 : El Brete : Lecho : Estancia : Argentina","324018","247353"
"UPDATE","2023-04-07","2677965","459561e0-eae6-45b7-bca4-86ac1b901fa7","Dinosaur Institute","LACM-DI 161282","","","","","","femur - check cast","DILACM8148 : El Brete : Lecho : Estancia : Argentina","324018","247353"
"UPDATE","2023-04-07","2592925","8db6cd3f-ffc2-4e17-b0f3-f539f6428eea","Dinosaur Institute","LACM-DI 161208","","","","","","Cranial; maxilla with teeth","DILACM4684 : LACM 4684 : Fruita Paleontological Area : Morrison : Brushy Basin + Salt Wash : Mesa : Colorado : USA : Portlandian","913214","8949"
"UPDATE","2023-04-07","2604438","8e2ed3ce-8047-4f86-a596-6d5129ce46b2","Dinosaur Institute","LACM-DI 161252","","","","","","16-C: dorsal rib","DILACM7683 : LACM 7683 : Shumway Point East : Morrison : Brushy Basin : San Juan : Utah : USA : Kimmeridgian","916190","8818"
"""


def test_read_csv_from_string(tmp_path):
    # Write sample CSV to a temp file
    csv_file = tmp_path / "sample.csv"
    csv_file.write_text(SAMPLE_CSV, encoding="utf-8")

    df = csv_parser.read_csv(str(csv_file))
    assert isinstance(df, pd.DataFrame)

    # Basic sanity checks
    assert "irn" in df.columns
    assert df.iloc[0]["irn"] == 2677267
    assert df.shape[0] >= 1
