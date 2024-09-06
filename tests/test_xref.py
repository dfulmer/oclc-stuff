import responses
import pytest
import json
import time
from oclc_xrefs.xref import Xref
from oclc_xrefs.alma_bib import AlmaBib
from oclc_xrefs.worldcat_bib import WorldcatBib

@pytest.fixture
def mms_id():
   return "99187608627106381"

@pytest.fixture
def oclc_num():
   return "1354771677"

@pytest.fixture
def alma_bib_json():
  with open('tests/fixtures/alma_bib.json') as f:
     output = json.load(f)
  return output

@pytest.fixture
def alma_bib(alma_bib_json):
  return AlmaBib(alma_bib_json) 

@pytest.fixture
def worldcat_bib_xml():
  with open('tests/fixtures/worldcat_bib.xml') as f:
     output = f.read()
  return output

@pytest.fixture
def worldcat_bib(worldcat_bib_xml):
  return WorldcatBib(worldcat_bib_xml) 

def worldcat_request(worldcat_bib_xml, oclc_num):
   responses.post( 
       'https://oauth.oclc.org/token',
       json={
            "token_type": "Bearer",
            "access_token": "asdfoiw37850234lkjsdfsdf",
            "refresh_token": "sldvafkjw34509s8dfsdf",
            "expires_in": 3600,
            "expires_at": time.time() + 3600},
       status=200
    ) 
   responses.get(f"https://metadata.api.oclc.org/worldcat/manage/bibs/{oclc_num}",
                  body=worldcat_bib_xml,
                  status=200)

def alma_request(alma_bib_json, mms_id, status=200):
    return responses.get( 
        f"https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/{mms_id}?expand=None&view=full",
        json=alma_bib_json, 
        status=status
        ) 

def test_initialize():
    xref = Xref(mms_id="99andothernumbers", oclc_num="oclcnumber")
    assert xref.mms_id == "99andothernumbers"
    assert xref.oclc_num == "oclcnumber"

@responses.activate
def test_mms_id_is_in_alma(alma_bib_json, mms_id):
    alma_request(alma_bib_json,mms_id)
    xref = Xref(mms_id=mms_id, oclc_num="oclcnumber")
    assert(xref.mms_id_is_in_alma) == True 

def test_alma_oclc_nums(alma_bib, mms_id, oclc_num):
    xref = Xref(mms_id=mms_id, oclc_num=oclc_num, alma_bib=alma_bib)
    assert(xref.alma_oclc_nums) == [oclc_num]


def test_alma_035a_matches_xref_when_match(alma_bib, mms_id, oclc_num):
    xref = Xref(mms_id=mms_id, oclc_num=oclc_num, alma_bib=alma_bib)
    assert(xref.alma_035a_matches_xref) == True

def test_alma_035a_matches_xref_when_no_match(alma_bib, mms_id):
    xref = Xref(mms_id=mms_id, oclc_num="whatever", alma_bib=alma_bib)
    assert(xref.alma_035a_matches_xref) == False

@responses.activate
def test_worldcat_bib_fetched_from_worldcat(alma_bib, mms_id, oclc_num, worldcat_bib_xml):
   worldcat_request(worldcat_bib_xml, oclc_num)
   xref = Xref(mms_id=mms_id, oclc_num=oclc_num, alma_bib=alma_bib)
   assert(xref.worldcat_bib.oclc_num) == oclc_num

def test_matches_any_worldcat_019(alma_bib_json, worldcat_bib, mms_id, oclc_num):
   xml = alma_bib_json["anies"][0]
   alma_bib_json["anies"] = [xml.replace(oclc_num, "0123456789")]
   alma_bib = AlmaBib(alma_bib_json)
   xref = Xref(mms_id=mms_id, oclc_num=oclc_num, alma_bib=alma_bib, worldcat_bib=worldcat_bib)
   assert(xref.matches_any_worldcat_019) == True

def test_matches_any_worldcat_019_failure(alma_bib, worldcat_bib, mms_id, oclc_num):
   xref = Xref(mms_id=mms_id, oclc_num=oclc_num, alma_bib=alma_bib, worldcat_bib=worldcat_bib)
   assert(xref.matches_any_worldcat_019) == False