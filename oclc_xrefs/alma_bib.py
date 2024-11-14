import requests
import io
import os
import pymarc
import re
import copy

class AlmaBib:
    def __init__(self, bib):
        self.bib = bib
        raw_xml_string = bib["anies"][0]
        self.record = pymarc.parse_xml_to_array(io.StringIO(raw_xml_string))[0]
         
    
    @classmethod
    def fetch(cls, mms_id):
        api_key = os.environ["ALMA_API_KEY"]
        headers = {
            "content": "application/json",
            "Accept": "application/json",
            "Authorization": f"apikey { api_key }"
        }
        resp = requests.get(f"https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/{mms_id}?expand=None&view=full",
                     headers=headers)
        if resp.status_code == 200:
            return AlmaBib(resp.json())
        else:
            return EmptyAlmaBib()

    @property 
    def oclc(self):
        output = []
        fields = self.record.get_fields("035") 
        for f in fields:
            for s in f.subfields:
                if s.code == "a" and re.search("OCoLC",s.value):
                  all_digits = re.findall(r'\d+', s.value)[0]
                  output.append(re.sub(r'^[0]+', r'', all_digits))
        return output
      
    @property 
    def is_in_alma(self):
        return True

    @property
    def has_no_oclc(self):
        pass

    @property
    def mms_id(self):
        return self.bib["mms_id"]

    """
    This needs to be filled out!
    """
    @property
    def has_908(self):
        pass

    def _clone_record(self):
        raw_xml_string = self.bib["anies"][0]
        return pymarc.parse_xml_to_array(io.StringIO(raw_xml_string))[0]

    def generate_updated_record(self, new_oclc_number, numbers_from_019=[]):
        new_record = self._clone_record()
        
        # removes existing oclc fields
        matches_oclc_prefix = lambda field: re.search("OCoLC", str(field))
        for field  in new_record.get_fields("035")[:]:
            if matches_oclc_prefix(field):
                new_record.remove_field(field)

        subfield_a = [pymarc.Subfield(code="a", value=f"(OCoLC){new_oclc_number}")] 
        subfield_zs = [pymarc.Subfield(code="z", value=f"(OCoLC){value}") for value in numbers_from_019]  

        # add fixed oclc field
        new_record.add_field(
            pymarc.Field(
                tag = '035',
                indicators = ['',''],
                subfields = subfield_a + subfield_zs)
        )
                
        
        return new_record 
    
    def update_035a(self, new_oclc_number, numbers_from_019=[]):
        new_record = self.generate_updated_record(new_oclc_number=new_oclc_number, numbers_from_019=numbers_from_019)
        xml = "<bib>" + str(pymarc.marcxml.record_to_xml(new_record).decode()) + "</bib>"
        
        api_key = os.environ["ALMA_API_KEY"]
        headers = {
            "content-type": "application/xml",
            "Accept": "application/json",
            "Authorization": f"apikey { api_key }"
        }
        params = {
           "check_match": "false",
           "override_lock": "true",
           "override_warning": "true",
           "stale_version_check": "false",
           "validate": "false"
        }
        resp = requests.put(f"https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/{self.mms_id}",
                     headers=headers, params=params, data=xml)
        if resp.status_code != 200:
            raise Exception(f"Alma returned status code resp.status_code")

class EmptyAlmaBib:
    @property
    def is_in_alma(self):
        return False
