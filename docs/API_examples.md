# PostgREST API

The DashVERSE API is powered by PostgREST, which automatically generates a REST API from the PostgreSQL database schema.

## Authentication

Generate a JWT token for write operations:

```shell
./scripts/generate-jwt.sh
export EVERSE_TOKEN="<generated-token>"
```

Read operations (GET) work without authentication. Write operations (POST, PATCH, DELETE) require a valid JWT.

## Base URL

- Local: `http://localhost:3000`
- Production: `https://api.dashverse.example.com`

## Endpoints

### Core Tables

| Endpoint | Methods | Description |
|----------|---------|-------------|
| /software | GET, POST | Software catalog |
| /dimensions | GET, POST | Quality dimensions |
| /indicators | GET, POST | Quality indicators |
| /assessment | GET, POST | Assessments (resqui compatible) |

### Dashboard Views (read-only)

| Endpoint | Description |
|----------|-------------|
| /assessments_detailed | Full assessment info with check counts |
| /checks_detailed | Unnested checks with indicator/dimension info |
| /assessment_summary | Aggregated metrics per software |
| /dimension_coverage | Pass/fail counts per dimension |
| /indicator_results | Check results grouped by indicator and status |
| /software_quality_scores | Quality scores per software and dimension |
| /assessment_trends | Monthly assessment statistics |
| /common_issues | Frequently failing indicators |

## Examples

### List Software

```shell
curl http://localhost:3000/software
```

### List Dimensions

```shell
curl http://localhost:3000/dimensions
```

### List Indicators

```shell
curl http://localhost:3000/indicators
```

### Get Dimension Coverage

```shell
curl http://localhost:3000/dimension_coverage
```

### Get Software Quality Scores

```shell
curl http://localhost:3000/software_quality_scores
```

### Submit Assessment (resqui format)

This endpoint accepts the JSON-LD format used by resqui:

```shell
curl -X POST http://localhost:3000/assessment \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $EVERSE_TOKEN" \
  -H "Prefer: return=representation" \
  -d '{
    "@context": "https://w3id.org/everse/rsqa/0.0.1/",
    "@type": "SoftwareQualityAssessment",
    "dateCreated": "2025-11-17T10:00:00Z",
    "license": "CC0-1.0",
    "author": {
      "@type": "Person",
      "name": "Quality Pipeline"
    },
    "assessedSoftware": {
      "@type": "SoftwareApplication",
      "name": "example-tool",
      "softwareVersion": "1.0.0",
      "url": "https://github.com/example/tool"
    },
    "checks": [
      {
        "@type": "CheckResult",
        "assessesIndicator": {"@id": "IND-LIC-001"},
        "checkingSoftware": {"name": "howfairis", "version": "0.14.2"},
        "process": "Check for LICENSE file",
        "status": {"@id": "Pass"},
        "output": "true",
        "evidence": "Found LICENSE file"
      }
    ]
  }'
```

### Filtering

PostgREST supports query parameters for filtering:

```shell
# Get indicators for a specific dimension
curl "http://localhost:3000/indicators?quality_dimension=eq.DIM-TST"

# Get assessments for specific software
curl "http://localhost:3000/assessment_summary?software_name=eq.example-tool"

# Get failed checks only
curl "http://localhost:3000/checks_detailed?status=like.*Fail*"
```

### Pagination

```shell
# Get first 10 results
curl "http://localhost:3000/software?limit=10"

# Get results 11-20
curl "http://localhost:3000/software?limit=10&offset=10"
```

### Selecting Fields

```shell
# Get only name and identifier
curl "http://localhost:3000/software?select=name,identifier"
```

## Error Responses

| Status | Meaning |
|--------|---------|
| 200 | Success |
| 201 | Created |
| 401 | Unauthorized (missing/invalid JWT) |
| 403 | Forbidden (insufficient permissions) |
| 404 | Not found |
| 409 | Conflict (duplicate key) |

## References

- PostgREST documentation: https://postgrest.org/en/stable/
