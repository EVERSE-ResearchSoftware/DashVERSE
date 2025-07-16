# Example API Calls

**Note:** To run the API calls, you will need JSON Web Token (JWT). The examples here use `EVERSE_TOKEN` environment variable to use the JWT. Make sure you set it correctly before running the API calls.

```shell
export EVERSE_TOKEN="<YOUR_JWT>"
```

## Software

### List software

```shell
curl https://db.YOUR_DOMAIN/software
```

### Add software

The example below **does not** use the JWT so it should fail.

```shell
curl -X 'POST' \
  'https://db.dashverse.cloud/software' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
    "id": 0,
    "identifier": "some identifier",
    "name": "HowFairIS",
    "description": "Checks compliance",
    "url": "https://www.howfairis.com/",
    "isAccessibleForFree": true,
    "license": "Apache 2.0"
  }'
```

The example below uses the JWT to add software.

```shell
curl -X 'POST' \
  'https://db.dashverse.cloud/software' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $EVERSE_TOKEN" \
  -d '{
    "id": 0,
    "identifier": "some identifier",
    "name": "HowFairIS",
    "description": "Checks compliance",
    "url": "https://www.howfairis.com/",
    "isAccessibleForFree": true,
    "license": "Apache 2.0"
  }'
```

List available software after adding:

```shell
curl https://db.YOUR_DOMAIN/software
```
