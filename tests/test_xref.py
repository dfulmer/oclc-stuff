import responses
import pytest
import json
from oclc_xrefs.xref import Xref

@pytest.fixture
def mms_id():
   return "99187608627106381"

@pytest.fixture
def alma_bib():
  with open('tests/fixtures/alma_bib.json') as f:
     output = json.load(f)
  return output

@responses.activate
def test_mms_id_in_alma(alma_bib, mms_id):
    resp = responses.get( 
        f"https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/{mms_id}?expand=None&view=full",
        json=alma_bib, 
        status=200
        ) 
    xref = Xref(mms_id=mms_id, oclc_num="oclcnumber")
    assert(xref.mms_id_in_alma()) == True 


def test_initialize():
    xref = Xref(mms_id="99andothernumbers", oclc_num="oclcnumber")
    assert xref.mms_id == "99andothernumbers"
    assert xref.oclc_num == "oclcnumber"
