import pytest
import json
import responses
from responses import matchers
import pymarc
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

def test_oclc_leading_zeros(alma_bib, oclc_num):
    xml = alma_bib["anies"][0] 
    alma_bib["anies"][0] = xml.replace(oclc_num, "(OCoLC)ocm005055")
    bib = AlmaBib(alma_bib)
    assert bib.oclc == ["5055"]

def test_generate_update_bib_has_new_oclc_num_in_035a(alma_bib):
    new_record = AlmaBib(alma_bib).generate_updated_record(new_oclc_number="123")
    control_numbers = []
    for f in new_record.get_fields("035"):
        control_numbers.append(f["a"])
    
    assert("(OCoLC)123" in control_numbers)


def test_generate_update_bib_has_019_in_035a(alma_bib):
    new_record = AlmaBib(alma_bib).generate_updated_record(new_oclc_number="123",numbers_from_019=["555","222"])
    control_numbers = []
    for f in new_record.get_fields("035"):
        control_numbers.extend(f.get_subfields("z"))
     
    assert("(OCoLC)555" in control_numbers)
    assert("(OCoLC)222" in control_numbers)

@responses.activate
def test_update_035a(alma_bib, mms_id):
    new_record = AlmaBib(alma_bib).generate_updated_record(new_oclc_number="123",numbers_from_019=["555","222"])
    xml = "<bib>" + str(pymarc.marcxml.record_to_xml(new_record).decode()) + "</bib>"
    resp = responses.put( 
       f"https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/{mms_id}",
       match=[
           matchers.query_param_matcher({
             "check_match": "false",
             "override_lock": "true",
             "override_warning": "true",
             "stale_version_check": "false",
             "validate": "false"
       }), 
        #TODO figure out how to test this
        # matchers.urlencoded_params_matcher(xml)
       ],
       status=200
    ) 

    AlmaBib(alma_bib).update_035a(new_oclc_number="123",numbers_from_019=["555","222"])

    assert(resp.call_count) == 1


    