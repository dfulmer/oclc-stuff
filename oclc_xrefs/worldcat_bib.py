import pymarc
import io
import os
from oauthlib.oauth2 import BackendApplicationClient
from requests_oauthlib import OAuth2Session
from requests.auth import HTTPBasicAuth
from requests import Session


class WorldcatBib:
    token_url='https://oauth.oclc.org/token'
    scope = ['WorldCatMetadataAPI:manage_bibs']
    client_id = os.environ["WORLDCAT_CLIENT_ID"]
    secret = os.environ["WORLDCAT_SECRET"]

    def __init__(self, bib):
        self.record = pymarc.parse_xml_to_array(io.StringIO(bib))[0]

    @classmethod
    def fetch(cls, oclc_num):
        auth = HTTPBasicAuth(cls.client_id, cls.secret)
        client = BackendApplicationClient(client_id=cls.client_id, scope=cls.scope)
        oauth = OAuth2Session(client=client)
        token = oauth.fetch_token(token_url=cls.token_url, auth=auth, 
                                  include_client_id=True)

        s = Session()
        s.headers.update({"Authorization": f'Bearer {token["access_token"]}'})
        response = s.get(f"https://metadata.api.oclc.org/worldcat/manage/bibs/{oclc_num}")
        if response.status_code == 200:
          return WorldcatBib(response.text)
        else: 
          return EmptyWorldcatBib()
        
    

    @property
    def oclc_num(self):
      return self.record["001"].value()

    @property
    def is_in_worldcat(self):
       return True

    @property
    def tag_019(self):
      try:
        output = self.record["019"].get_subfields("a")
      except:
        output = []
      return output
    
    def has_any_019(self, values):
      for alma_oclc_num in values:
         for tag_019_num in self.tag_019:
            if alma_oclc_num == tag_019_num:
               return True
      return False       
          


class EmptyWorldcatBib:
    @property
    def is_in_worldcat(self):
        return False       