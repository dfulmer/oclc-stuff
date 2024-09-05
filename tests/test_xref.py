import responses
import pytest
import json
from oclc_xrefs.xref import Xref

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

def alma_request(alma_bib, mms_id, status=200):
    return responses.get( 
        f"https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/{mms_id}?expand=None&view=full",
        json=alma_bib, 
        status=status
        ) 

@responses.activate
def test_mms_id_is_in_alma(alma_bib, mms_id):
    alma_request(alma_bib,mms_id)
    xref = Xref(mms_id=mms_id, oclc_num="oclcnumber")
    assert(xref.mms_id_is_in_alma) == True 

@responses.activate
def test_alma_oclc_nums(alma_bib, mms_id, oclc_num):
    alma_request(alma_bib,mms_id)
    xref = Xref(mms_id=mms_id, oclc_num=oclc_num)
    assert(xref.alma_oclc_nums) == [oclc_num]


@responses.activate
def test_alma_035a_matches_xref_when_match(alma_bib, mms_id, oclc_num):
    alma_request(alma_bib,mms_id) 
    xref = Xref(mms_id=mms_id, oclc_num=oclc_num)
    assert(xref.alma_035a_matches_xref) == True

@responses.activate
def test_alma_035a_matches_xref_when_no_match(alma_bib, mms_id, oclc_num):
    alma_request(alma_bib,mms_id) 
    xref = Xref(mms_id=mms_id, oclc_num="whatever")
    assert(xref.alma_035a_matches_xref) == False

def test_no_matches():

def test_initialize():
    xref = Xref(mms_id="99andothernumbers", oclc_num="oclcnumber")
    assert xref.mms_id == "99andothernumbers"
    assert xref.oclc_num == "oclcnumber"
