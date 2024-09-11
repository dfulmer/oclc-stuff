import pytest
import responses
import requests
import time
from oclc_xrefs.worldcat_bib import WorldcatBib

@pytest.fixture
def oclc_num():
   return "1354771677"

@pytest.fixture
def tag_019_a1():
   return "1329221766"

@pytest.fixture
def tag_019_a2():
   return "123456789"

@pytest.fixture
def worldcat_bib():
  with open('tests/fixtures/worldcat_bib.xml') as f:
     output = f.read() 
  return output


@responses.activate
def test_fetch_success(worldcat_bib, oclc_num):
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
                  body=worldcat_bib,
                  status=200)

    bib = WorldcatBib.fetch(oclc_num)
    assert(bib.oclc_num) == oclc_num 

# @responses.activate
# def test_fetch_fail(mms_id):
#     responses.get( 
#        "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/99187608627106381?expand=None&view=full",
#        json={"msg": "error"},
#        status=500
#     ) 
#     bib = AlmaBib.fetch(mms_id)
#     assert(bib.is_in_alma) == False

def test_oclc(worldcat_bib, oclc_num):
    bib = WorldcatBib(worldcat_bib)
    assert bib.oclc_num == oclc_num

def test_oclc(worldcat_bib, oclc_num):
    bib = WorldcatBib(worldcat_bib)
    assert bib.oclc_num == oclc_num

def test_tag_019_with_empty_019(worldcat_bib):
   bib = WorldcatBib(worldcat_bib.replace("tag=\"019\"","tag=\"020\""))
   assert bib.tag_019 == []

def test_tag_019(worldcat_bib, tag_019_a1, tag_019_a2):
   bib = WorldcatBib(worldcat_bib)
   assert bib.tag_019 == [ tag_019_a1, tag_019_a2 ]

def test_has_any_019_success(worldcat_bib, tag_019_a1):
   bib = WorldcatBib(worldcat_bib)
   assert bib.has_any_019(["1234", tag_019_a1]) == True

def test_has_any_019_failure(worldcat_bib):
   bib = WorldcatBib(worldcat_bib)
   assert bib.has_any_019(["1234"]) == False
