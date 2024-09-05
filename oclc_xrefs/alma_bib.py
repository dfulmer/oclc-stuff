import requests
import io
import os
import pymarc
import re

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
                  output.append(re.findall(r'\d+', s.value)[0])
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

class EmptyAlmaBib:
    @property
    def is_in_alma(self):
        return False
