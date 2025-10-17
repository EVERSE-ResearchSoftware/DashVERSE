# Example API Calls

**Note:** To run the API calls, you will need JSON Web Token (JWT). The examples here use `EVERSE_TOKEN` environment variable to use the JWT. Make sure you set it correctly before running the API calls.

```shell
export EVERSE_TOKEN="<YOUR_JWT>"
```

If you are using the helper CLI in `examples/dashverse_cli_example.py`, configure the Superset API credentials first:

```shell
export DASHVERSE_API_URL="https://dashverse.cloud/api/v1"
export DASHVERSE_USERNAME="<superset-username>"
export DASHVERSE_PASSWORD="<superset-password>"
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

## Assessments

### Retrieve full assessments

```shell
curl https://db.YOUR_DOMAIN/assessments?select=*,assessment_creators(*),assessment_software(*),assessment_checks(*)
```

### Create an assessment (multi-step)

```shell
ASSESSMENT_ID=$(curl -s -X 'POST' \
  'https://db.YOUR_DOMAIN/assessments' \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $EVERSE_TOKEN" \
  -H 'Prefer: return=representation' \
  -H 'Content-Type: application/json' \
  -d '{
    "@context": "https://w3id.org/everse/rsqa/0.0.1/",
    "@type": "SoftwareQualityAssessment",
    "name": "Quality Assessment for CFFinit v2.3.1",
    "description": "An automated assessment run on 2025-06-19.",
    "dateCreated": "2025-06-19T17:52:00Z",
    "license": { "@id": "https://creativecommons.org/publicdomain/zero/1.0/" }
  }' | jq '.[0].id')

curl -X 'POST' \
  "https://db.YOUR_DOMAIN/assessment_creators" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $EVERSE_TOKEN" \
  -H 'Prefer: return=representation' \
  -H 'Content-Type: application/json' \
  -d '{
    "assessment_id": '"$ASSESSMENT_ID"',
    "@type": "schema:Person",
    "name": "Faruk Diblen",
    "email": "f.diblen@example.com"
  }'

curl -X 'POST' \
  "https://db.YOUR_DOMAIN/assessment_software" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $EVERSE_TOKEN" \
  -H 'Prefer: return=representation' \
  -H 'Content-Type: application/json' \
  -d '{
    "assessment_id": '"$ASSESSMENT_ID"',
    "@type": "schema:SoftwareApplication",
    "name": "CFFinit",
    "version": "2.3.1",
    "url": "https://github.com/citation-file-format/cff-initializer-javascript",
    "identifier_uri": "https://doi.org/10.5281/zenodo.8224012"
  }'

curl -X 'POST' \
  "https://db.YOUR_DOMAIN/assessment_checks" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $EVERSE_TOKEN" \
  -H 'Prefer: return=representation' \
  -H 'Content-Type: application/json' \
  -d '[
    {
      "assessment_id": '"$ASSESSMENT_ID"',
      "@type": "CheckResult",
      "indicator_uri": "https://w3id.org/everse/i/indicators/license",
      "checking_software_name": "howfairis",
      "checking_software_uri": "https://w3id.org/everse/tools/howfairis",
      "checking_software_version": "0.14.2",
      "process": "Searches for a LICENSE file.",
      "status_uri": "schema:CompletedActionStatus",
      "output": "true",
      "evidence": "Found license file: 'LICENSE'."
    }
  ]'
```

> **Note:** PostgREST returns created rows when the `Prefer: return=representation` header is provided. Capture the `id` from the first insert to link child resources. You can batch multiple check rows in one request as shown above.
>
> The snippet uses `jq` to extract the new `assessment_id`. If `jq` is not available, inspect the JSON response manually or leverage PostgREST's `Location` header.

For additional payload structures or filters, consult the PostgREST documentation and the schema overview in `docs/Database.md`.
