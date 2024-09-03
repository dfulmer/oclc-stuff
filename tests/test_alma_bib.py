import pytest
import json
import responses
import requests
from oclc_xrefs.alma_bib import AlmaBib


@pytest.fixture
def alma_bib():
  with open('tests/fixtures/alma_bib.json') as f:
     output = json.load(f)
  return output

@pytest.fixture
def alma_bib_str(alma_bib):
  return json.dumps(alma_bib)

@responses.activate
def test_fetch(alma_bib):
    responses.add(responses.GET, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/99187608627106381?expand=None&view=full",
                  json=alma_bib, status=200) 
    bib = AlmaBib.fetch("99187608627106381")
    assert(bib.mms_id()) == "99187608627106381"


def test_mms_id(alma_bib):
    bib = AlmaBib(alma_bib)
    assert bib.mms_id() == "99187608627106381"