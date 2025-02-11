import requests
import json
import logging


logging.basicConfig(
    filename="dashverse_cli.log",
    encoding="utf-8",
    filemode="a",
    format="{asctime} - {levelname} - {message}",
    style="{",
    datefmt="%Y-%m-%d %H:%M",
    level=logging.DEBUG
)


class DashverseCli():

    def __init__(self):
        self.api_url = "http://localhost:8088/api/v1"
        self.login_url = f"{self.api_url}/security/login"
        self.session = requests.Session()
        self.access_token = None
        self.csrf_token = None


    def showInfo(self):
        print(f"API url        : {self.api_url}")
        print(f"login url      : {self.login_url}")
        print(f"access_token   : {self.access_token}")
        print(f"csrf_token     : {self.csrf_token}")
        print(f"session headers: {self.session.headers}")


    def get_bearer_token(self):
        if self.access_token:
            return self.access_token
        else:
            payload = {"password": "admin", "provider": "db", "username": "admin"}
            headers = {"Content-Type": "application/json"}
            response = requests.request(
                "POST", f"{self.api_url}/security/login", json=payload, headers=headers
            )
            if response.status_code != 200:
                raise Exception(f"Got HTTP code of {response.status_code} from {url}; expected 200")
            self.access_token = response.json()["access_token"]
            return self.access_token


    def get_csrf_token(self):
        if self.csrf_token:
            return self.csrf_token
        else:
            print("Getting csrf_token")
            payload = ""
            headers = {"Authorization": f"Bearer {self.access_token}"}
            response = requests.request(
                "GET", f"{self.api_url}/security/csrf_token/", data=payload, headers=headers
            )
            self.csrf_token = response.json()["result"]
            return self.csrf_token


    def get_superset_access_token(self):
        # https://stackoverflow.com/a/78762443
        # Authenticate and get access token
        endpoint = "/api/v1/security/login"
        response = self.session.post(
            self.login_url,
            json={
                "username": "admin",
                "password": "admin",
                "provider": "db",
                "refresh": True
            },
        )
        if response.status_code != 200:
            raise Exception(f"Got HTTP code of {response.status_code} from {url}; expected 200")
        access_token = response.json()["access_token"]
        self.session.headers.update({
            "Authorization": f"Bearer {access_token}"
        })


    def get_superset_csrf_token(self):
        url = f"{self.api_url}/security/csrf_token/"
        response = self.session.get(url)
        if response.status_code != 200:
            raise Exception(f"Got HTTP code of {response.status_code} from {url}; expected 200")
        token = response.json()["result"]
        self.session.headers.update({
            "X-CSRFToken": token
        })


    def create_dataset_for_table(self, table_name):
        url = f"{self.api_url}/dataset/"
        payload = {
            "catalog": "superset",
            "database": 1,
            "schema": "public",
            "table_name": f"{table_name}"
        }
        response = self.session.post(
            url,
            headers=self.session.headers,
            json=payload
        )

        # Check the response status code
        if response.status_code != 201:
            raise Exception(
                f"Got HTTP code of {response.status_code} from {url}; expected 201. See the server logs"
            )

        # parse the response as JSON
        try:
            response_json = response.json()
        except Exception as exception:
            raise Exception(f"Could not parse response from {url} as JSON, see the server logs)")

        dataset_id = response_json["id"]
        print(f"Status {response.status_code}: Dataset {dataset_id} was created for the {table_name} table!")

        # log the response
        logging.info(f"Status {response.status_code}: Dataset {dataset_id} was created for the {table_name} table")
        logging.info(json.dumps(response.json(), indent=4))


    def create_everse_datasets(self):
        cli.create_dataset_for_table(table_name="indicators")
        cli.create_dataset_for_table(table_name="dimensions")
        cli.create_dataset_for_table(table_name="software")

if __name__ == "__main__":

    cli = DashverseCli()

    # cli.get_bearer_token()
    # cli.get_csrf_token()

    cli.get_superset_access_token()
    cli.get_superset_csrf_token()
    cli.create_everse_datasets()

    # cli.showInfo()



