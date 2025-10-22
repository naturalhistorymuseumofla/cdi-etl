import pytest

from etl.extractors import airtable_fetcher


class DummyTable:
    def __init__(self, api_key, base_id, table_name):
        self.api_key = api_key
        self.base_id = base_id
        self.table_name = table_name

    def all(self):
        return [
            {"id": "rec1", "fields": {"name": "Alice"}},
            {"id": "rec2", "fields": {"name": "Bob"}},
        ]


def test_fetch_data_from_airtable_success(monkeypatch):
    # Patch the Table class used in the module so no network calls are made.
    monkeypatch.setattr(airtable_fetcher, "Table", DummyTable)

    # Patch settings with valid credentials
    class DummySettings:
        airtable_pat = "fake_key"
        airtable_base_id = "fake_base"

    monkeypatch.setattr(airtable_fetcher, "settings", DummySettings)

    # Call using the real table name used in the project
    records = airtable_fetcher.fetch_data_from_airtable("Elements")

    assert isinstance(records, list)
    assert len(records) == 2
    assert records[0]["fields"]["name"] == "Alice"


def test_fetch_data_from_airtable_missing_credentials(monkeypatch):
    # Ensure settings has no credentials
    class DummySettings:
        airtable_pat = None
        airtable_base_id = None

    monkeypatch.setattr(airtable_fetcher, "settings", DummySettings)

    with pytest.raises(RuntimeError) as excinfo:
        airtable_fetcher.fetch_data_from_airtable("MyTable")

    assert "Airtable credentials missing" in str(excinfo.value)
