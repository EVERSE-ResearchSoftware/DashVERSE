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

## Assessment

### List assessment

```shell
curl https://db.YOUR_DOMAIN/assessment
```

### Add assessment

```shell
curl -X 'POST' \
  'https://db.YOUR_DOMAIN/assessment' \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $EVERSE_TOKEN" \
  -H 'Prefer: return=representation' \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Quality Assessment for CFFinit v2.3.1",
    "description": "An automated assessment of the CFFinit tool based on the EVERSE software quality indicators, run on 2025-06-19.",
    "creator": [{
        "@type": "schema:Person",
        "name": "Faruk Diblen",
        "email": "f.diblen@example.com"
    }],
    "dateCreated": "2025-06-19T17:52:00Z",
    "license": { "@id": "https://creativecommons.org/publicdomain/zero/1.0/" },
    "assessedSoftware": {
        "@type": "schema:SoftwareApplication",
        "name": "CFFinit",
        "softwareVersion": "2.3.1",
        "url": "https://github.com/citation-file-format/cff-initializer-javascript",
        "schema:identifier": {
            "@id": "https://doi.org/10.5281/zenodo.8224012"
        }
    },
    "checks": [
        {
            "@type": "CheckResult",
            "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/license" },
            "checkingSoftware": {
                "@type": "schema:SoftwareApplication",
                "name": "howfairis",
                "@id": "https://w3id.org/everse/tools/howfairis",
                "softwareVersion": "0.14.2"
            },
            "process": "Searches for a file named 'LICENSE' or 'LICENSE.md' in the repository root.",
            "status": { "@id": "schema:CompletedActionStatus" },
            "output": "true",
            "evidence": "Found license file: 'LICENSE'."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/citation" },
            "checkingSoftware": {
                "@type": "schema:SoftwareApplication",
                "name": "howfairis",
                "@id": "https://w3id.org/everse/tools/howfairis",
                "softwareVersion": "0.14.2"
            },

            "process": "Searches for a 'CITATION.cff' file in the repository root and validates its syntax.",
            "status": { "@id": "schema:CompletedActionStatus" },
            "output": "valid",
            "evidence": "Found valid CITATION.cff file in repository root."
        }
    ]
}'
```
