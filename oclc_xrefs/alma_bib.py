import requests
import os

class AlmaBib:
    def __init__(self, bib):
        self.bib = bib
    
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
    def is_in_alma(self):
        return True


    @property
    def mms_id(self):
        return self.bib["mms_id"]

class EmptyAlmaBib:
    @property
    def is_in_alma(self):
        return False
