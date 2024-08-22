from oauthlib.oauth2 import BackendApplicationClient
from requests_oauthlib import OAuth2Session
from requests.auth import HTTPBasicAuth
from requests import Session
import sys

def wcfetch():
  try:
    # Get the OCLC number we are interested in
    ocnumber = sys.argv[1]

    # Open the .env file and read the contents
    with open('.env', 'r') as file:
       # Initialize variables
       client_id = None
       client_secret = None

       # Loop through each line in the file
       for line in file:
        # Split the line by the equals sign
        key, value = line.strip().split('=')

        # Assign the values to the corresponding variables
        if key == 'CLIENT_ID':
            client_id = value
        elif key == 'CLIENT_SECRET':
            client_secret = value

    token_url='https://oauth.oclc.org/token'
    scope = ['WorldCatMetadataAPI:manage_bibs']

    auth = HTTPBasicAuth(client_id, client_secret)

    client = BackendApplicationClient(client_id=client_id, scope=scope)
    oauth = OAuth2Session(client=client)
    token = oauth.fetch_token(token_url=token_url, auth=auth, include_client_id=True)

    s = Session()
    s.headers.update({"Authorization": f'Bearer {token["access_token"]}'})
    response = s.get(f"https://metadata.api.oclc.org/worldcat/manage/bibs/{ocnumber}")

    print(response.text)
  except:
    print("Error")

if __name__ == '__main__':
  wcfetch()
  