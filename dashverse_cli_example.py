import requests
import json
import logging

# see https://superset.apache.org/docs/api/
#base_url = "http://localhost:8088/api/v1"
base_url = "https://dashverse.cloud/api/v1"


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
    """ This example talks to superset API to run various operations.
    """

    def __init__(self):
        # self.host_url = "http://localhost:8088"
        self.host_url = "https://dashverse.cloud"
        self.api_url = f"{self.host_url}/api/v1"
        self.api_docs_url = f"{self.host_url}/swagger/v1"
        self.bearer_token = self._get_bearer_token()
        self.csrf_token = self._get_csrf_token()
        self.request_headers = {
            "X-CSRFToken": self.csrf_token,
            "Authorization": f"Bearer {self.bearer_token}",
        }

    def _get_bearer_token(self):
        payload = {"password": "admin", "provider": "db", "username": "admin"}
        headers = {"Content-Type": "application/json"}
        response = requests.request(
            "POST", f"{base_url}/security/login", json=payload, headers=headers
        )
        return response.json()["access_token"]

    def _get_csrf_token(self):
        payload = ""
        headers = {"Authorization": f"Bearer {self._get_bearer_token()}"}
        response = requests.request(
            "GET", f"{base_url}/security/csrf_token/", data=payload, headers=headers
        )
        return response.json()["result"]

    def showInfo(self):
        print(f"API url        : {self.api_url}")
        print(f"API docs        : {self.api_docs_url}")
        print(f"bearer_token   : {self.bearer_token}")
        print(f"csrf_token     : {self.csrf_token}")
        print(f"request headers: {self.request_headers}")


    def get_chart_info(self, chart_id):
        response = requests.get(f"{base_url}/chart/{chart_id}", headers=self.request_headers)
        return response.json()

    def get_db_list(self):
        response = requests.get(f"{base_url}/database/", headers=self.request_headers)
        return response.json()

    def get_db(self, db_id):
        response = requests.get(f"{base_url}/database/{db_id}", headers=self.request_headers)
        return response.json()

    def get_db_tables(self, db_id):
        response = requests.get(f"{base_url}/database/{db_id}/tables", headers=self.request_headers)
        return response.json()

    def get_dataset_list(self):
        response = requests.get(f"{base_url}/dataset/", headers=self.request_headers)
        return response.json()



if __name__ == "__main__":

    cli = DashverseCli()


    everse_db_list = cli.get_db_list()
    print("Database list")
    json_str = json.dumps(everse_db_list, indent=4)
    print(json_str)

    everse_db = cli.get_db(1)
    print("Database info")
    json_str = json.dumps(everse_db, indent=4)
    print(json_str)

    everse_db_tables = cli.get_db_tables(1)
    print("Database tables")
    json_str = json.dumps(everse_db_tables, indent=4)
    print(json_str)

    everse_datasets = cli.get_dataset_list()
    print("Datasets")
    json_str = json.dumps(everse_datasets, indent=4)
    print(json_str)
