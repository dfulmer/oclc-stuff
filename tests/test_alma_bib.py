import pytest
import json
import responses
import requests
from oclc_xrefs.alma_bib import AlmaBib

@pytest.fixture
def mms_id():
    return "99187608627106381"

@pytest.fixture
def oclc_num():
   return "1354771677"

@pytest.fixture
def alma_bib():
  with open('tests/fixtures/alma_bib.json') as f:
     output = json.load(f)
  return output

@responses.activate
def test_fetch_success(alma_bib, mms_id):
    responses.get( 
       "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/99187608627106381?expand=None&view=full",
       json=alma_bib,
       status=200
    ) 
    bib = AlmaBib.fetch(mms_id)
    assert(bib.mms_id) == mms_id

@responses.activate
def test_fetch_fail(mms_id):
    responses.get( 
       "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/99187608627106381?expand=None&view=full",
       json={"msg": "error"},
       status=500
    ) 
    bib = AlmaBib.fetch(mms_id)
    assert(bib.is_in_alma) == False

def test_mms_id(alma_bib, mms_id):
    bib = AlmaBib(alma_bib)
    assert bib.mms_id == mms_id

def test_oclc(alma_bib, oclc_num):
    bib = AlmaBib(alma_bib)
    assert bib.oclc == [oclc_num]