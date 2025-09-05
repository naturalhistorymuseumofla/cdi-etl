"""Tests for the EMu XML parser.

This module uses a realistic EMu XML sample (including a processing
instruction `<?schema ... ?>`) to exercise `xml_parser.xml_to_json` and
related helpers.
"""

import textwrap

from etl.extractors import xml_parser

SAMPLE_XML = textwrap.dedent("""<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE table
[
    <!ELEMENT table	(tuple)*>
    <!ATTLIST table
                        name	CDATA #REQUIRED
    >

    <!ELEMENT tuple	(table|tuple|atom)*>
    <!ATTLIST tuple
                        name	CDATA #IMPLIED
    >

    <!ELEMENT atom	(#PCDATA)*>
    <!ATTLIST atom
                        name	CDATA #REQUIRED
                        type	CDATA "text"
                        size	CDATA "short"
    >
]
>
<?schema
    table           ecatalogue
        date            date_emu_record_modified
        date            date_emu_record_inserted
        text short      irn
        text short      emu_guid
        text short      catalogue_number
        text short      department
        text short      section
        text short      collection_name
        text short      form
        text long       description
        text long       level_of_description
        text long       title
        table           CreatorGroup
            text long       creator
            text short      CreRole
        end
        text short      date_created
        table           subjects
            text long       SubSubjects
        end
    end
?>
<!-- Data -->
<table name="ecatalogue">

    <!-- Row 1 -->
    <tuple>
        <atom name="date_emu_record_modified">2018-10-02</atom>
        <atom name="date_emu_record_inserted">2003-12-08</atom>
        <atom name="irn">531077</atom>
        <atom name="emu_guid">ecd496e0-790d-4d1e-a9e5-533c666838a9</atom>
        <atom name="catalogue_number">PROP-0035</atom>
        <atom name="department">Material Culture</atom>
        <atom name="section">Material Culture</atom>
        <atom name="collection_name"></atom>
        <atom name="form"></atom>
        <atom name="description">Adult male manikin, dressed as a photographer.</atom>
        <atom name="level_of_description"></atom>
        <atom name="title"></atom>
        <atom name="date_created"></atom>
    </tuple>
        <!-- Row 251 -->
    <tuple>
        <atom name="date_emu_record_modified">2018-11-05</atom>
        <atom name="date_emu_record_inserted">2009-08-10</atom>
        <atom name="irn">530258</atom>
        <atom name="emu_guid">ee46464d-3443-4eab-81fa-71bce4fec208</atom>
        <atom name="catalogue_number">L.1297- &lt;3&gt;</atom>
        <atom name="department">Material Culture</atom>
        <atom name="section">Material Culture</atom>
        <atom name="collection_name"></atom>
        <atom name="form"></atom>
        <atom name="description">Old Westinghouse, type socket (fits above lamp) with drop cord  and part of ceiling rosette. [LIC]</atom>
        <atom name="level_of_description"></atom>
        <atom name="title"></atom>
        <table name="CreatorGroup">
            <tuple>
                <atom name="creator">Westinghouse Electric Corporation</atom>
                <atom name="CreRole">Manufacturer</atom>
            </tuple>
        </table>
        <atom name="date_created"></atom>
    </tuple>

</table>
""")


def test_xml_to_json_with_real_sample(tmp_path):
    f = tmp_path / "sample.xml"
    f.write_text(SAMPLE_XML, encoding="utf-8")

    rows = xml_parser.xml_to_json(str(f))
    # Expect at least two rows
    assert isinstance(rows, list)
    assert len(rows) >= 2

    # First row checks
    r0 = rows[0]
    assert r0.get("irn") == "531077"
    assert r0.get("department") == "Material Culture"

    # Second row contains CreatorGroup as a list
    r1 = rows[1]
    assert isinstance(r1.get("CreatorGroup"), list)
    cg = r1.get("CreatorGroup", [])[0]
    assert cg.get("creator") == "Westinghouse Electric Corporation"
    assert cg.get("CreRole") == "Manufacturer"
